// SPDX-License-Identifier: Apache-2.0
//
// Native automatic-update channel for immutable CentL26 macOS snapshots.

import AppKit
import CryptoKit
import Darwin
import Foundation
import WebKit

enum CentL26UpdateContract {
    enum Decision: Equatable {
        case upToDate
        case offerNewerPublishedBuild
        case installedBuildIsNewer
        case conflictingBuildIdentity
    }

    struct SnapshotIdentity: Equatable {
        let buildSequence: UInt64
        let buildCommit: String
    }

    static let messageHandlerName = "centl26Update"
    static let productName = "CentL26"
    static let productVersion = "26.7.0"
    static let bundleIdentifier = "org.freecomputation.centl"
    static let releaseSchema = "org.freecomputation.centl.macos-release/2"
    static let buildSchema = "org.freecomputation.centl.build/1"
    static let releaseURL = URL(
        string: "https://api.github.com/repos/chasebryan/centl/releases?per_page=100"
    )!
    static let maximumMetadataBytes = 256 * 1024
    static let maximumReleaseListBytes = 2 * 1024 * 1024
    static let maximumArchiveBytes: Int64 = 1_073_741_824

    static func manifestName(
        architecture: String,
        buildSequence: UInt64,
        buildCommit: String
    ) -> String {
        archiveBaseName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        ) + ".release.json"
    }

    static func archiveName(
        architecture: String,
        buildSequence: UInt64,
        buildCommit: String
    ) -> String {
        archiveBaseName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        ) + ".zip"
    }

    static func checksumName(
        architecture: String,
        buildSequence: UInt64,
        buildCommit: String
    ) -> String {
        archiveName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        ) + ".sha256"
    }

    static func decision(
        installedSequence: UInt64,
        installedCommit: String,
        publishedSequence: UInt64,
        publishedCommit: String
    ) -> Decision {
        if publishedSequence > installedSequence { return .offerNewerPublishedBuild }
        if publishedSequence < installedSequence { return .installedBuildIsNewer }
        return installedCommit == publishedCommit ? .upToDate : .conflictingBuildIdentity
    }

    static func releaseTag(buildSequence: UInt64, buildCommit: String) -> String {
        "centl26-build-\(paddedSequence(buildSequence))-\(buildCommit)"
    }

    static func snapshotIdentity(tagName: String) -> SnapshotIdentity? {
        let prefix = "centl26-build-"
        guard tagName.hasPrefix(prefix) else { return nil }
        let fields = tagName.dropFirst(prefix.count).split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 2,
              fields[0].count == 8,
              fields[0].allSatisfy(\.isNumber),
              let buildSequence = UInt64(fields[0]),
              buildSequence >= 1,
              buildSequence <= 9_999,
              isSafeCommit(String(fields[1])),
              tagName == releaseTag(buildSequence: buildSequence, buildCommit: String(fields[1]))
        else { return nil }
        return SnapshotIdentity(buildSequence: buildSequence, buildCommit: String(fields[1]))
    }

    static func isImmutableSnapshotRelease(
        tagName: String,
        name: String?,
        draft: Bool,
        prerelease: Bool,
        immutable: Bool
    ) -> Bool {
        snapshotIdentity(tagName: tagName) != nil
            && name == productName
            && !draft
            && !prerelease
            && immutable
    }

    enum SnapshotSelection: Equatable {
        case none
        case selected(Int)
        case conflicting
    }

    static func selectNewestCompleteSnapshot(
        identities: [(tag: String, name: String?, draft: Bool, prerelease: Bool, immutable: Bool)],
        assetSets: [[String: [Int64]]],
        architecture: String
    ) -> SnapshotSelection {
        guard identities.count == assetSets.count else { return .conflicting }
        var complete: [(index: Int, identity: SnapshotIdentity)] = []
        for (index, identity) in identities.enumerated() {
            guard isImmutableSnapshotRelease(
                tagName: identity.tag,
                name: identity.name,
                draft: identity.draft,
                prerelease: identity.prerelease,
                immutable: identity.immutable
            ), let snapshot = snapshotIdentity(tagName: identity.tag) else {
                continue
            }
            guard firstCompleteReleaseIndex(
                [assetSets[index]],
                architecture: architecture,
                buildSequence: snapshot.buildSequence,
                buildCommit: snapshot.buildCommit
            ) == 0 else {
                continue
            }
            complete.append((index, snapshot))
        }
        guard let newestSequence = complete.map(\.identity.buildSequence).max() else {
            return .none
        }
        let newest = complete.filter { $0.identity.buildSequence == newestSequence }
        let commits = Set(newest.map(\.identity.buildCommit))
        guard newest.count == 1, commits.count == 1 else {
            return .conflicting
        }
        return .selected(newest[0].index)
    }

    static func validate(
        manifestData: Data,
        architecture: String,
        assetName: String,
        releaseTag: String
    ) throws -> CentL26ReleaseManifest {
        guard manifestData.count <= maximumMetadataBytes else {
            throw CentL26UpdateError("The published update manifest is unexpectedly large.")
        }
        let manifest: CentL26ReleaseManifest
        do {
            manifest = try JSONDecoder().decode(CentL26ReleaseManifest.self, from: manifestData)
        } catch {
            throw CentL26UpdateError("The published update manifest is not valid JSON.")
        }

        guard let snapshot = snapshotIdentity(tagName: releaseTag) else {
            throw CentL26UpdateError("The published update tag is not a CentL26 snapshot identity.")
        }
        let expectedManifest = manifestName(
            architecture: architecture,
            buildSequence: manifest.buildSequence,
            buildCommit: manifest.buildCommit
        )
        let expectedArchive = archiveName(
            architecture: architecture,
            buildSequence: manifest.buildSequence,
            buildCommit: manifest.buildCommit
        )
        guard assetName == expectedManifest,
              manifest.schema == releaseSchema,
              manifest.product == productName,
              manifest.productVersion == productVersion,
              manifest.bundleIdentifier == bundleIdentifier,
              manifest.architecture == architecture,
              manifest.buildSequence == snapshot.buildSequence,
              manifest.buildCommit == snapshot.buildCommit,
              manifest.sourceState == "clean",
              manifest.qualification == "release-qualified",
              manifest.nativeRuntimeQualification == "pinned-match",
              manifest.signing == "developer-id",
              manifest.notarized,
              manifest.archive == expectedArchive,
              isSafeCommit(manifest.buildCommit),
              isSHA256(manifest.sha256)
        else {
            throw CentL26UpdateError(
                "The published update does not satisfy the CentL26 release contract."
            )
        }
        return manifest
    }

    static func validateChecksum(
        _ data: Data,
        manifest: CentL26ReleaseManifest,
        architecture: String
    ) throws {
        guard data.count <= maximumMetadataBytes,
              let text = String(data: data, encoding: .utf8)
        else {
            throw CentL26UpdateError("The published update checksum is invalid.")
        }
        let fields = text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\r" || $0 == "\n" })
        let expectedArchive = archiveName(
            architecture: architecture,
            buildSequence: manifest.buildSequence,
            buildCommit: manifest.buildCommit
        )
        guard fields.count == 2,
              fields[0].lowercased() == manifest.sha256.lowercased(),
              fields[1] == Substring(expectedArchive)
        else {
            throw CentL26UpdateError(
                "The published checksum and release manifest do not identify the same archive."
            )
        }
    }

    static func sha256(of file: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var hasher = SHA256()
        while true {
            let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
            if data.isEmpty { break }
            hasher.update(data: data)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func permittedDownloadURL(_ url: URL?) -> Bool {
        guard let url, url.scheme == "https", url.user == nil, url.password == nil else {
            return false
        }
        return [
            "api.github.com",
            "github.com",
            "objects.githubusercontent.com",
            "release-assets.githubusercontent.com",
            "github-releases.githubusercontent.com",
        ].contains(url.host?.lowercased() ?? "")
    }

    static func stagingDirectory(for application: URL) throws -> URL {
        guard application.lastPathComponent == "CentL26.app",
              application.isFileURL,
              application.path.hasPrefix("/"),
              !application.path.contains("/../")
        else {
            throw CentL26UpdateError("CentL26 is running from an unsupported application path.")
        }
        let parent = application.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw CentL26UpdateError(
                "CentL26 cannot update this copy because \(parent.path) is not writable. " +
                "Move CentL26.app to a user-writable Applications folder or reinstall it there."
            )
        }
        return parent.appendingPathComponent(
            ".CentL26-update-\(UUID().uuidString)",
            isDirectory: true
        )
    }

    static func cleanupStagingDirectories(near application: URL) {
        guard application.lastPathComponent == "CentL26.app" else { return }
        let parent = application.deletingLastPathComponent()
        guard let allChildren = try? FileManager.default.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        ) else { return }
        for child in allChildren {
            let prefix = ".CentL26-update-"
            guard child.lastPathComponent.hasPrefix(prefix) else { continue }
            let suffix = String(child.lastPathComponent.dropFirst(prefix.count))
            guard UUID(uuidString: suffix) != nil,
                  let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
                  values.isDirectory == true,
                  values.isSymbolicLink != true
            else { continue }
            try? FileManager.default.removeItem(at: child)
        }
    }

    static func runSelfTest(bundle: Bundle) throws {
        let architecture = (bundle.object(forInfoDictionaryKey: "CentLBuildArchitecture") as? String)
            ?? "arm64"
        let buildSequence: UInt64 = 852
        let buildCommit = "0123456789abcdef0123456789abcdef01234567"
        let releaseTag = self.releaseTag(buildSequence: buildSequence, buildCommit: buildCommit)
        let archive = archiveName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        let digest = String(repeating: "a", count: 64)
        let json = """
        {
          "schema":"\(releaseSchema)",
          "product":"\(productName)",
          "product_version":"\(productVersion)",
          "bundle_identifier":"\(bundleIdentifier)",
          "architecture":"\(architecture)",
          "build_commit":"\(buildCommit)",
          "build_sequence":\(buildSequence),
          "source_state":"clean",
          "qualification":"release-qualified",
          "native_runtime_qualification":"pinned-match",
          "signing":"developer-id",
          "notarized":true,
          "archive":"\(archive)",
          "sha256":"\(digest)"
        }
        """
        let manifest = try validate(
            manifestData: Data(json.utf8),
            architecture: architecture,
            assetName: manifestName(
                architecture: architecture,
                buildSequence: buildSequence,
                buildCommit: buildCommit
            ),
            releaseTag: releaseTag
        )
        try validateChecksum(
            Data("\(digest)  \(archive)\n".utf8),
            manifest: manifest,
            architecture: architecture
        )

        var rejectedMismatch = false
        do {
            try validateChecksum(
                Data("\(String(repeating: "b", count: 64))  \(archive)\n".utf8),
                manifest: manifest,
                architecture: architecture
            )
        } catch {
            rejectedMismatch = true
        }
        guard rejectedMismatch else {
            throw CentL26UpdateError("The updater accepted a checksum mismatch.")
        }

        let manifestAssetName = self.manifestName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        let checksumAssetName = self.checksumName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        let releaseSets: [[String: [Int64]]] = [
            [
                manifestAssetName: [512],
                archive: [4096],
            ],
            [
                manifestAssetName: [512],
                archive: [4096],
                checksumAssetName: [96],
            ],
        ]
        guard firstCompleteReleaseIndex(
            releaseSets,
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        ) == 1 else {
            throw CentL26UpdateError("The updater did not skip an incomplete release asset set deterministically.")
        }
        let releaseIdentities = [
            (tag: "some-other-release", name: Optional(productName), draft: false, prerelease: false, immutable: true),
            (tag: releaseTag, name: Optional(productName), draft: false, prerelease: false, immutable: false),
            (tag: releaseTag, name: Optional(productName), draft: false, prerelease: false, immutable: true),
        ]
        let eligibleAssetSets = zip(releaseIdentities, [releaseSets[1], releaseSets[1], releaseSets[0]])
            .filter { entry in
                let identity = entry.0
                return isImmutableSnapshotRelease(
                    tagName: identity.tag,
                    name: identity.name,
                    draft: identity.draft,
                    prerelease: identity.prerelease,
                    immutable: identity.immutable
                )
            }
            .map { $0.1 }
        guard eligibleAssetSets.count == 1,
              firstCompleteReleaseIndex(
                eligibleAssetSets,
                architecture: architecture,
                buildSequence: buildSequence,
                buildCommit: buildCommit
              ) == nil
        else {
            throw CentL26UpdateError("The updater accepted assets outside the exact CentL26 release channel.")
        }
        let olderTag = self.releaseTag(buildSequence: buildSequence - 1, buildCommit: buildCommit)
        let completeSet: [String: [Int64]] = [
            manifestAssetName: [512],
            archive: [4096],
            checksumAssetName: [96],
        ]
        let selectionIdentities = [
            (tag: "centl26", name: Optional(productName), draft: false, prerelease: false, immutable: false),
            (tag: olderTag, name: Optional(productName), draft: false, prerelease: false, immutable: true),
            (tag: releaseTag, name: Optional(productName), draft: false, prerelease: false, immutable: true),
        ]
        guard selectNewestCompleteSnapshot(
            identities: selectionIdentities,
            assetSets: [completeSet, completeSet, completeSet],
            architecture: architecture
        ) == .selected(2),
        selectNewestCompleteSnapshot(
            identities: [
                (tag: releaseTag, name: Optional(productName), draft: false, prerelease: false, immutable: true),
                (tag: releaseTag, name: Optional(productName), draft: false, prerelease: false, immutable: true),
            ],
            assetSets: [completeSet, completeSet],
            architecture: architecture
        ) == .conflicting,
        selectNewestCompleteSnapshot(
            identities: [
                (tag: "centl26", name: Optional(productName), draft: false, prerelease: false, immutable: false),
            ],
            assetSets: [completeSet],
            architecture: architecture
        ) == .none
        else {
            throw CentL26UpdateError("The updater snapshot-selection contract differs.")
        }
        guard decision(
            installedSequence: buildSequence,
            installedCommit: manifest.buildCommit,
            publishedSequence: buildSequence,
            publishedCommit: manifest.buildCommit
        ) == .upToDate,
        decision(
            installedSequence: buildSequence - 1,
            installedCommit: manifest.buildCommit,
            publishedSequence: buildSequence,
            publishedCommit: manifest.buildCommit
        ) == .offerNewerPublishedBuild,
        decision(
            installedSequence: buildSequence + 1,
            installedCommit: manifest.buildCommit,
            publishedSequence: buildSequence,
            publishedCommit: manifest.buildCommit
        ) == .installedBuildIsNewer,
        decision(
            installedSequence: buildSequence,
            installedCommit: String(repeating: "f", count: 40),
            publishedSequence: buildSequence,
            publishedCommit: manifest.buildCommit
        ) == .conflictingBuildIdentity
        else {
            throw CentL26UpdateError("The updater build-identity decision contract differs.")
        }
        guard permittedDownloadURL(URL(
            string: "https://release-assets.githubusercontent.com/github-production-release-asset/example"
        )),
        !permittedDownloadURL(URL(
            string: "https://unrelated.githubusercontent.com/centl26/update.zip"
        ))
        else {
            throw CentL26UpdateError("The updater release-download host allowlist differs.")
        }

        let helper = bundle.bundleURL
            .appendingPathComponent("Contents/Helpers/centl26-update-installer", isDirectory: false)
        guard FileManager.default.isExecutableFile(atPath: helper.path) else {
            throw CentL26UpdateError("The packaged update installer helper is missing.")
        }
    }

    private static func paddedSequence(_ buildSequence: UInt64) -> String {
        String(format: "%08llu", buildSequence)
    }

    private static func archiveBaseName(
        architecture: String,
        buildSequence: UInt64,
        buildCommit: String
    ) -> String {
        "CentL26-\(productVersion)-build-\(paddedSequence(buildSequence))-" +
            "\(buildCommit.prefix(12))-macos-\(architecture)"
    }

    private static func isSafeCommit(_ value: String) -> Bool {
        guard value.count == 40 else { return false }
        return value.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    private static func isSHA256(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { $0.isHexDigit && !$0.isUppercase }
    }

    static func firstCompleteReleaseIndex(
        _ releaseAssetSizes: [[String: [Int64]]],
        architecture: String,
        buildSequence: UInt64,
        buildCommit: String
    ) -> Int? {
        let manifest = manifestName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        let archive = archiveName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        let checksum = checksumName(
            architecture: architecture,
            buildSequence: buildSequence,
            buildCommit: buildCommit
        )
        return releaseAssetSizes.firstIndex { sizes in
            guard let manifests = sizes[manifest], manifests.count == 1,
                  manifests[0] > 0,
                  manifests[0] <= Int64(maximumMetadataBytes),
                  let archives = sizes[archive], archives.count == 1,
                  archives[0] > 0,
                  archives[0] <= maximumArchiveBytes,
                  let checksums = sizes[checksum], checksums.count == 1,
                  checksums[0] > 0,
                  checksums[0] <= Int64(maximumMetadataBytes)
            else { return false }
            return true
        }
    }
}

struct CentL26ReleaseManifest: Decodable {
    let schema: String
    let product: String
    let productVersion: String
    let bundleIdentifier: String
    let architecture: String
    let buildCommit: String
    let buildSequence: UInt64
    let sourceState: String
    let qualification: String
    let nativeRuntimeQualification: String
    let signing: String
    let notarized: Bool
    let archive: String
    let sha256: String

    enum CodingKeys: String, CodingKey {
        case schema, product, architecture, signing, notarized, archive, sha256
        case productVersion = "product_version"
        case bundleIdentifier = "bundle_identifier"
        case buildCommit = "build_commit"
        case buildSequence = "build_sequence"
        case sourceState = "source_state"
        case qualification
        case nativeRuntimeQualification = "native_runtime_qualification"
    }
}

private struct CentL26GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let draft: Bool
    let prerelease: Bool
    let immutable: Bool
    let assets: [CentL26GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case name, draft, prerelease, immutable, assets
        case tagName = "tag_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        draft = try container.decode(Bool.self, forKey: .draft)
        prerelease = try container.decode(Bool.self, forKey: .prerelease)
        immutable = try container.decodeIfPresent(Bool.self, forKey: .immutable) ?? false
        assets = try container.decode([CentL26GitHubAsset].self, forKey: .assets)
    }
}

private struct CentL26GitHubAsset: Decodable {
    let name: String
    let browserDownloadURL: URL
    let size: Int64

    enum CodingKeys: String, CodingKey {
        case name, size
        case browserDownloadURL = "browser_download_url"
    }
}

private struct CentL26UpdateCandidate {
    let manifest: CentL26ReleaseManifest
    let archiveAsset: CentL26GitHubAsset
}

struct CentL26UpdateError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? { message }
}

private struct CentL26ProcessResult {
    let terminationStatus: Int32
    let output: String
}

private enum CentL26Process {
    static func run(_ executable: String, arguments: [String]) throws -> CentL26ProcessResult {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        do {
            try process.run()
        } catch {
            throw CentL26UpdateError("Could not run \(executable): \(error.localizedDescription)")
        }
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        return CentL26ProcessResult(
            terminationStatus: process.terminationStatus,
            output: String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

private enum CentL26CodeSignature {
    static func teamIdentifier(for application: URL) throws -> String {
        let result = try CentL26Process.run(
            "/usr/bin/codesign",
            arguments: ["--display", "--verbose=4", application.path]
        )
        guard result.terminationStatus == 0,
              result.output.contains("Authority=Developer ID Application:"),
              let line = result.output.split(separator: "\n")
                .first(where: { $0.hasPrefix("TeamIdentifier=") })
        else {
            throw CentL26UpdateError("CentL26 is not signed by a Developer ID Application certificate.")
        }
        let team = line.dropFirst("TeamIdentifier=".count)
        guard !team.isEmpty,
              team.count <= 32,
              team.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) })
        else {
            throw CentL26UpdateError("CentL26 has an invalid signing-team identity.")
        }
        return String(team)
    }

    static func verify(application: URL, expectedTeam: String) throws {
        let verification = try CentL26Process.run(
            "/usr/bin/codesign",
            arguments: ["--verify", "--deep", "--strict", application.path]
        )
        guard verification.terminationStatus == 0 else {
            throw CentL26UpdateError(
                "The downloaded CentL26 code signature is invalid. \(verification.output)"
            )
        }
        let actualTeam = try teamIdentifier(for: application)
        guard actualTeam == expectedTeam else {
            throw CentL26UpdateError("The downloaded update was signed by a different developer team.")
        }
        let assessment = try CentL26Process.run(
            "/usr/sbin/spctl",
            arguments: ["--assess", "--type", "exec", "--verbose", application.path]
        )
        guard assessment.terminationStatus == 0 else {
            throw CentL26UpdateError(
                "macOS did not accept the downloaded notarized application. \(assessment.output)"
            )
        }
    }
}

final class CentL26UpdateMessageHandler: NSObject, WKScriptMessageHandler {
    private let port: UInt16
    private let onCheck: () -> Void

    init(port: UInt16, onCheck: @escaping () -> Void) {
        self.port = port
        self.onCheck = onCheck
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == CentL26UpdateContract.messageHandlerName,
              message.frameInfo.isMainFrame,
              let url = message.frameInfo.request.url,
              url.scheme == "http",
              url.host == "127.0.0.1",
              (url.port ?? 80) == Int(port),
              let body = message.body as? [String: Any],
              body.count == 1,
              body["action"] as? String == "check"
        else {
            NSSound.beep()
            return
        }
        onCheck()
    }
}

final class CentL26UpdateController {
    private enum State {
        case idle
        case checking
        case downloading
        case ready
    }

    private let bundle: Bundle
    private let presentingWindow: () -> NSWindow?
    private let beforeRelaunch: () -> Void
    private let logger: (String) -> Void
    private let helperOutputHandle: () throws -> FileHandle
    private let session: URLSession
    private var state = State.idle

    init(
        bundle: Bundle,
        presentingWindow: @escaping () -> NSWindow?,
        beforeRelaunch: @escaping () -> Void,
        logger: @escaping (String) -> Void,
        helperOutputHandle: @escaping () throws -> FileHandle
    ) {
        self.bundle = bundle
        self.presentingWindow = presentingWindow
        self.beforeRelaunch = beforeRelaunch
        self.logger = logger
        self.helperOutputHandle = helperOutputHandle
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 300
        configuration.httpAdditionalHeaders = [
            "Accept": "application/vnd.github+json",
            "User-Agent": "CentL26/26.0.0 macOS updater",
            "X-GitHub-Api-Version": "2022-11-28",
        ]
        session = URLSession(configuration: configuration)
    }

    deinit {
        session.invalidateAndCancel()
    }

    func checkForUpdates() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard case .idle = state else {
            NSSound.beep()
            return
        }

        let signingMode = bundle.object(forInfoDictionaryKey: "CentLSigningMode") as? String ?? "adhoc"
        if signingMode != "developer-id" {
            present(
                title: "Local Repository Build",
                message: "This is a local source build of CentL26. Click the Update button at the bottom-right of the window to check origin/main, pull commits, and rebuild.",
                style: .informational
            )
            return
        }

        let installed: InstalledIdentity
        do {
            installed = try installedIdentity()
        } catch {
            present(
                title: "Automatic Updates Unavailable",
                message: error.localizedDescription,
                style: .informational
            )
            return
        }

        state = .checking
        logger("checking CentL26 release channel")
        fetchCandidate(architecture: installed.architecture) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .failure(let error):
                    self.state = .idle
                    self.logger("update check failed: \(error.localizedDescription)")
                    self.present(title: "Update Check Failed", message: error.localizedDescription, style: .warning)
                case .success(let candidate):
                    switch CentL26UpdateContract.decision(
                        installedSequence: installed.buildSequence,
                        installedCommit: installed.buildCommit,
                        publishedSequence: candidate.manifest.buildSequence,
                        publishedCommit: candidate.manifest.buildCommit
                    ) {
                    case .upToDate:
                        self.state = .idle
                        self.logger("CentL26 is current at \(installed.buildSequence)/\(installed.buildCommit)")
                        self.present(
                            title: "CentL26 Is Up to Date",
                            message: "This copy already matches the newest frozen CentL26 snapshot.",
                            style: .informational
                        )
                    case .offerNewerPublishedBuild:
                        self.confirmDownload(candidate: candidate, installed: installed)
                    case .installedBuildIsNewer:
                        self.state = .idle
                        self.logger("installed CentL26 \(installed.buildSequence) is newer than frozen snapshot \(candidate.manifest.buildSequence)")
                        self.present(
                            title: "CentL26 Is Ahead of the Frozen Channel",
                            message: "This copy is newer than the newest frozen CentL26 snapshot and will not be replaced.",
                            style: .informational
                        )
                    case .conflictingBuildIdentity:
                        self.state = .idle
                        self.logger("frozen snapshot identity conflicts at sequence \(installed.buildSequence)")
                        self.present(
                            title: "Update Channel Conflict",
                            message: "A frozen CentL26 snapshot uses the same build sequence with a different source identity. This copy will not be replaced.",
                            style: .warning
                        )
                    }
                }
            }
        }
    }

    private struct InstalledIdentity {
        let application: URL
        let architecture: String
        let buildCommit: String
        let buildSequence: UInt64
        let signingTeam: String
        let helper: URL
    }

    private func installedIdentity() throws -> InstalledIdentity {
        let application = bundle.bundleURL.standardizedFileURL
        guard application.lastPathComponent == "CentL26.app",
              application.path.hasPrefix("/"),
              (try? application.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) != true
        else {
            throw CentL26UpdateError("Automatic updates require a normal CentL26.app installation.")
        }
        guard bundle.object(forInfoDictionaryKey: "CentLSigningMode") as? String == "developer-id" else {
            throw CentL26UpdateError(
                "Automatic updates are enabled only in a Developer ID signed CentL26 release build."
            )
        }
        guard let architecture = bundle.object(forInfoDictionaryKey: "CentLBuildArchitecture") as? String,
              ["arm64", "x86_64"].contains(architecture),
              let buildCommit = bundle.object(forInfoDictionaryKey: "CentLBuildCommit") as? String,
              buildCommit.count == 40,
              buildCommit.allSatisfy({ $0.isHexDigit && !$0.isUppercase }),
              let buildSequence = unsignedInteger(bundle.object(forInfoDictionaryKey: "CentLBuildSequence")),
              buildSequence >= 1,
              buildSequence <= 9_999
        else {
            throw CentL26UpdateError("This CentL26 copy has incomplete build identity metadata.")
        }
        let buildManifestURL = application
            .appendingPathComponent("Contents/Resources/build-manifest.json", isDirectory: false)
        let buildData = try Data(contentsOf: buildManifestURL)
        guard let buildDocument = try JSONSerialization.jsonObject(with: buildData) as? [String: Any],
              buildDocument["schema"] as? String == CentL26UpdateContract.buildSchema,
              buildDocument["product"] as? String == CentL26UpdateContract.productName,
              buildDocument["product_version"] as? String == CentL26UpdateContract.productVersion,
              buildDocument["bundle_identifier"] as? String == CentL26UpdateContract.bundleIdentifier,
              buildDocument["architecture"] as? String == architecture,
              buildDocument["build_commit"] as? String == buildCommit,
              unsignedInteger(buildDocument["build_sequence"]) == buildSequence,
              buildDocument["source_state"] as? String == "clean",
              buildDocument["signing"] as? String == "developer-id",
              let native = buildDocument["native_runtime"] as? [String: Any],
              native["qualification"] as? String == "pinned-match"
        else {
            throw CentL26UpdateError(
                "Automatic updates require a clean, pinned-runtime CentL26 release build."
            )
        }
        _ = try CentL26UpdateContract.stagingDirectory(for: application)
        let helper = application
            .appendingPathComponent("Contents/Helpers/centl26-update-installer", isDirectory: false)
        guard FileManager.default.isExecutableFile(atPath: helper.path) else {
            throw CentL26UpdateError("This CentL26 copy does not include its automatic-update installer.")
        }
        let signingTeam = try CentL26CodeSignature.teamIdentifier(for: application)
        try CentL26CodeSignature.verify(application: application, expectedTeam: signingTeam)
        return InstalledIdentity(
            application: application,
            architecture: architecture,
            buildCommit: buildCommit,
            buildSequence: buildSequence,
            signingTeam: signingTeam,
            helper: helper
        )
    }

    private func fetchCandidate(
        architecture: String,
        completion: @escaping (Result<CentL26UpdateCandidate, Error>) -> Void
    ) {
        fetchData(from: CentL26UpdateContract.releaseURL, maximumBytes: CentL26UpdateContract.maximumReleaseListBytes) {
            [weak self] result in
            guard let self else { return }
            do {
                let data = try result.get()
                let releases = try JSONDecoder().decode([CentL26GitHubRelease].self, from: data)
                let identities = releases.map { release in
                    (
                        tag: release.tagName,
                        name: release.name,
                        draft: release.draft,
                        prerelease: release.prerelease,
                        immutable: release.immutable
                    )
                }
                let assetSets = releases.map { release in
                    Dictionary(grouping: release.assets, by: \.name).mapValues { $0.map(\.size) }
                }
                let selectedIndex: Int
                switch CentL26UpdateContract.selectNewestCompleteSnapshot(
                    identities: identities,
                    assetSets: assetSets,
                    architecture: architecture
                ) {
                case .none:
                    throw CentL26UpdateError(
                        "No published CentL26 update is available for this Mac architecture."
                    )
                case .conflicting:
                    throw CentL26UpdateError(
                        "Published CentL26 snapshots conflict at the same build sequence."
                    )
                case .selected(let index):
                    selectedIndex = index
                }
                let release = releases[selectedIndex]
                guard let snapshot = CentL26UpdateContract.snapshotIdentity(tagName: release.tagName) else {
                    throw CentL26UpdateError("The CentL26 release channel identity differs.")
                }
                let manifestName = CentL26UpdateContract.manifestName(
                    architecture: architecture,
                    buildSequence: snapshot.buildSequence,
                    buildCommit: snapshot.buildCommit
                )
                let manifestAssets = release.assets.filter { $0.name == manifestName }
                guard manifestAssets.count == 1,
                      manifestAssets[0].size > 0,
                      manifestAssets[0].size <= Int64(CentL26UpdateContract.maximumMetadataBytes)
                else {
                    throw CentL26UpdateError("The release contains an ambiguous or invalid CentL26 manifest asset.")
                }
                let manifestAsset = manifestAssets[0]
                self.fetchData(from: manifestAsset.browserDownloadURL, maximumBytes: CentL26UpdateContract.maximumMetadataBytes) {
                    manifestResult in
                    do {
                        let manifestData = try manifestResult.get()
                        let manifest = try CentL26UpdateContract.validate(
                            manifestData: manifestData,
                            architecture: architecture,
                            assetName: manifestAsset.name,
                            releaseTag: release.tagName
                        )
                        let archiveMatches = release.assets.filter { $0.name == manifest.archive }
                        let checksumName = CentL26UpdateContract.checksumName(
                            architecture: architecture,
                            buildSequence: manifest.buildSequence,
                            buildCommit: manifest.buildCommit
                        )
                        let checksumMatches = release.assets.filter { $0.name == checksumName }
                        guard archiveMatches.count == 1,
                              archiveMatches[0].size > 0,
                              archiveMatches[0].size <= CentL26UpdateContract.maximumArchiveBytes,
                              checksumMatches.count == 1,
                              checksumMatches[0].size > 0,
                              checksumMatches[0].size <= Int64(CentL26UpdateContract.maximumMetadataBytes)
                        else {
                            throw CentL26UpdateError(
                                "The release does not contain one complete CentL26 archive/checksum pair."
                            )
                        }
                        self.fetchData(
                            from: checksumMatches[0].browserDownloadURL,
                            maximumBytes: CentL26UpdateContract.maximumMetadataBytes
                        ) { checksumResult in
                            do {
                                try CentL26UpdateContract.validateChecksum(
                                    try checksumResult.get(),
                                    manifest: manifest,
                                    architecture: architecture
                                )
                                completion(.success(CentL26UpdateCandidate(
                                    manifest: manifest,
                                    archiveAsset: archiveMatches[0]
                                )))
                            } catch {
                                completion(.failure(error))
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func fetchData(
        from url: URL,
        maximumBytes: Int,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        guard CentL26UpdateContract.permittedDownloadURL(url) else {
            completion(.failure(CentL26UpdateError("The release channel returned an unsupported download URL.")))
            return
        }
        let task = session.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(CentL26UpdateError("The release channel returned no HTTP response.")))
                return
            }
            if response.statusCode == 403 || response.statusCode == 429 {
                completion(.failure(CentL26UpdateError(
                    "The public release channel is temporarily rate-limited. Try checking again later."
                )))
                return
            }
            guard (200...299).contains(response.statusCode),
                  CentL26UpdateContract.permittedDownloadURL(response.url),
                  let data,
                  data.count <= maximumBytes
            else {
                completion(.failure(CentL26UpdateError("The release channel returned an invalid response.")))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

    private func confirmDownload(candidate: CentL26UpdateCandidate, installed: InstalledIdentity) {
        guard let window = presentingWindow(), window.attachedSheet == nil else {
            state = .idle
            NSSound.beep()
            return
        }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "A Published CentL26 Build Is Available"
        alert.informativeText =
            "This keeps the public product name CentL26 and replaces snapshot " +
            "\(installed.buildSequence)/\(shortCommit(installed.buildCommit)) with frozen snapshot " +
            "\(candidate.manifest.buildSequence)/\(shortCommit(candidate.manifest.buildCommit))."
        alert.addButton(withTitle: "Download Update")
        alert.addButton(withTitle: "Not Now")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            if response == .alertFirstButtonReturn {
                self.downloadAndPrepare(candidate: candidate, installed: installed)
            } else {
                self.state = .idle
            }
        }
    }

    private func downloadAndPrepare(candidate: CentL26UpdateCandidate, installed: InstalledIdentity) {
        state = .downloading
        logger("downloading CentL26 snapshot \(candidate.manifest.buildSequence)/\(candidate.manifest.buildCommit)")
        let staging: URL
        do {
            staging = try CentL26UpdateContract.stagingDirectory(for: installed.application)
            try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: false)
        } catch {
            state = .idle
            present(title: "Update Could Not Start", message: error.localizedDescription, style: .warning)
            return
        }

        guard CentL26UpdateContract.permittedDownloadURL(candidate.archiveAsset.browserDownloadURL) else {
            try? FileManager.default.removeItem(at: staging)
            state = .idle
            present(
                title: "Update Could Not Start",
                message: "The release channel returned an unsupported archive URL.",
                style: .warning
            )
            return
        }

        let task = session.downloadTask(with: candidate.archiveAsset.browserDownloadURL) {
            [weak self] temporaryURL, response, error in
            guard let self else { return }
            do {
                if let error { throw error }
                guard let response = response as? HTTPURLResponse,
                      (200...299).contains(response.statusCode),
                      CentL26UpdateContract.permittedDownloadURL(response.url),
                      let temporaryURL
                else {
                    throw CentL26UpdateError("The release channel returned an invalid archive response.")
                }
                let archive = staging.appendingPathComponent(candidate.manifest.archive, isDirectory: false)
                try FileManager.default.moveItem(at: temporaryURL, to: archive)
                let attributes = try FileManager.default.attributesOfItem(atPath: archive.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? -1
                guard size == candidate.archiveAsset.size,
                      size > 0,
                      size <= CentL26UpdateContract.maximumArchiveBytes
                else {
                    throw CentL26UpdateError("The downloaded archive size differs from the published asset.")
                }
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let stagedApplication = try self.verifyAndExpand(
                            archive: archive,
                            staging: staging,
                            candidate: candidate,
                            installed: installed
                        )
                        DispatchQueue.main.async {
                            self.state = .ready
                            self.confirmInstall(
                                stagedApplication: stagedApplication,
                                staging: staging,
                                installed: installed
                            )
                        }
                    } catch {
                        try? FileManager.default.removeItem(at: staging)
                        DispatchQueue.main.async {
                            self.state = .idle
                            self.logger("downloaded update rejected: \(error.localizedDescription)")
                            self.present(
                                title: "Downloaded Update Rejected",
                                message: error.localizedDescription,
                                style: .warning
                            )
                        }
                    }
                }
            } catch {
                try? FileManager.default.removeItem(at: staging)
                DispatchQueue.main.async {
                    self.state = .idle
                    self.logger("update download failed: \(error.localizedDescription)")
                    self.present(title: "Update Download Failed", message: error.localizedDescription, style: .warning)
                }
            }
        }
        task.resume()
    }

    private func verifyAndExpand(
        archive: URL,
        staging: URL,
        candidate: CentL26UpdateCandidate,
        installed: InstalledIdentity
    ) throws -> URL {
        let digest = try CentL26UpdateContract.sha256(of: archive)
        guard digest == candidate.manifest.sha256.lowercased() else {
            throw CentL26UpdateError("The downloaded archive failed its published SHA-256 digest.")
        }
        let expanded = staging.appendingPathComponent("expanded", isDirectory: true)
        try FileManager.default.createDirectory(at: expanded, withIntermediateDirectories: false)
        let extraction = try CentL26Process.run(
            "/usr/bin/ditto",
            arguments: ["-x", "-k", archive.path, expanded.path]
        )
        guard extraction.terminationStatus == 0 else {
            throw CentL26UpdateError("The downloaded archive could not be expanded. \(extraction.output)")
        }
        let children = try FileManager.default.contentsOfDirectory(
            at: expanded,
            includingPropertiesForKeys: nil
        )
        guard children.count == 1, children[0].lastPathComponent == "CentL26.app" else {
            throw CentL26UpdateError("The downloaded archive has an unexpected top-level layout.")
        }
        let application = children[0]
        try rejectSymbolicLinks(in: application)
        try validateExtractedApplication(
            application,
            manifest: candidate.manifest,
            expectedTeam: installed.signingTeam
        )
        return application
    }

    private func rejectSymbolicLinks(in application: URL) throws {
        guard let enumerator = FileManager.default.enumerator(
            at: application,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: []
        ) else {
            throw CentL26UpdateError("The downloaded application could not be inspected.")
        }
        for case let item as URL in enumerator {
            if try item.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink == true {
                throw CentL26UpdateError("The downloaded application unexpectedly contains a symbolic link.")
            }
        }
    }

    private func validateExtractedApplication(
        _ application: URL,
        manifest: CentL26ReleaseManifest,
        expectedTeam: String
    ) throws {
        guard let candidateBundle = Bundle(url: application),
              candidateBundle.bundleIdentifier == CentL26UpdateContract.bundleIdentifier,
              candidateBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
                == CentL26UpdateContract.productVersion,
              candidateBundle.object(forInfoDictionaryKey: "CentLBuildArchitecture") as? String
                == manifest.architecture,
              candidateBundle.object(forInfoDictionaryKey: "CentLBuildCommit") as? String
                == manifest.buildCommit,
              unsignedInteger(candidateBundle.object(forInfoDictionaryKey: "CentLBuildSequence"))
                == manifest.buildSequence,
              candidateBundle.object(forInfoDictionaryKey: "CentLSigningMode") as? String == "developer-id"
        else {
            throw CentL26UpdateError("The downloaded application identity differs from its release manifest.")
        }

        let buildManifestURL = application
            .appendingPathComponent("Contents/Resources/build-manifest.json", isDirectory: false)
        let data = try Data(contentsOf: buildManifestURL)
        guard let document = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              document["schema"] as? String == CentL26UpdateContract.buildSchema,
              document["product"] as? String == CentL26UpdateContract.productName,
              document["product_version"] as? String == CentL26UpdateContract.productVersion,
              document["bundle_identifier"] as? String == CentL26UpdateContract.bundleIdentifier,
              document["architecture"] as? String == manifest.architecture,
              document["build_commit"] as? String == manifest.buildCommit,
              unsignedInteger(document["build_sequence"]) == manifest.buildSequence,
              document["source_state"] as? String == "clean",
              document["signing"] as? String == "developer-id",
              let native = document["native_runtime"] as? [String: Any],
              native["qualification"] as? String == "pinned-match"
        else {
            throw CentL26UpdateError("The downloaded application build manifest is not release-qualified.")
        }
        try CentL26CodeSignature.verify(application: application, expectedTeam: expectedTeam)
    }

    private func confirmInstall(stagedApplication: URL, staging: URL, installed: InstalledIdentity) {
        guard let window = presentingWindow(), window.attachedSheet == nil else {
            try? FileManager.default.removeItem(at: staging)
            state = .idle
            NSSound.beep()
            return
        }
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "CentL26 Is Ready to Update"
        alert.informativeText =
            "The archive, manifest, checksum, notarization, and developer signature were verified. " +
            "CentL26 will close, replace this app atomically, and relaunch."
        alert.addButton(withTitle: "Install and Relaunch")
        alert.addButton(withTitle: "Later")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self else { return }
            if response == .alertFirstButtonReturn {
                do {
                    try self.launchInstaller(stagedApplication: stagedApplication, installed: installed)
                    self.logger("verified update handed to atomic installer")
                    self.beforeRelaunch()
                    NSApp.terminate(nil)
                } catch {
                    try? FileManager.default.removeItem(at: staging)
                    self.state = .idle
                    self.present(title: "Update Could Not Be Installed", message: error.localizedDescription, style: .warning)
                }
            } else {
                try? FileManager.default.removeItem(at: staging)
                self.state = .idle
            }
        }
    }

    private func launchInstaller(stagedApplication: URL, installed: InstalledIdentity) throws {
        let process = Process()
        let outputHandle = try helperOutputHandle()
        process.executableURL = installed.helper
        process.arguments = [
            "--install",
            String(getpid()),
            stagedApplication.path,
            installed.application.path,
        ]
        process.standardOutput = outputHandle
        process.standardError = outputHandle
        do {
            try process.run()
            try? outputHandle.close()
        } catch {
            try? outputHandle.close()
            throw CentL26UpdateError("The atomic update installer could not start: \(error.localizedDescription)")
        }
    }

    private func present(title: String, message: String, style: NSAlert.Style) {
        guard let window = presentingWindow(), window.attachedSheet == nil else {
            NSSound.beep()
            return
        }
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: window)
    }

    private func shortCommit(_ commit: String) -> String {
        String(commit.prefix(12))
    }

    private func unsignedInteger(_ value: Any?) -> UInt64? {
        if let number = value as? NSNumber {
            let converted = number.uint64Value
            return NSDecimalNumber(value: converted) == NSDecimalNumber(decimal: number.decimalValue)
                ? converted
                : nil
        }
        if let text = value as? String {
            return UInt64(text)
        }
        return nil
    }
}
