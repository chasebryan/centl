// SPDX-License-Identifier: Apache-2.0
//
// Native macOS application shell for CentL26.

import AppKit
import Darwin
import Foundation
import WebKit

private enum Product {
    static let name = "CentL26"
    static let organization = "Free Computation Foundation"
    static let preferredPort: UInt16 = 2626
    static let fallbackPortCount = 9
    static let readinessPath = "/__centl26"
    static let bundleIdentifier = "org.freecomputation.centl"
}

private struct StateDirectoryError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

private struct RuntimeContext {
    let stateDirectory: URL
    let diagnosticsURL: URL
    let buildCommit: String
    let providerManifestURL: URL?
    let providerEnvironment: [String: String]

    static func prepare(bundle: Bundle = .main) throws -> RuntimeContext {
        let fileManager = FileManager.default
        let environment = ProcessInfo.processInfo.environment
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).standardizedFileURL
        let stateDirectory: URL

        if let override = environment["CENTL26_STATE_DIR"] {
            guard override.hasPrefix("/") else {
                throw StateDirectoryError(message: "CENTL26_STATE_DIR must be an absolute path.")
            }
            let rawComponents = (override as NSString).pathComponents
            guard !rawComponents.contains("."), !rawComponents.contains("..") else {
                throw StateDirectoryError(message: "CENTL26_STATE_DIR may not contain '.' or '..' path components.")
            }
            // Preserve the validated lexical path. Foundation's
            // standardizedFileURL rewrites /private/tmp to the /tmp symlink,
            // which would defeat the intentional no-follow traversal below.
            stateDirectory = URL(fileURLWithPath: override, isDirectory: true)
        } else {
            stateDirectory = applicationSupport
                .appendingPathComponent(Product.organization, isDirectory: true)
                .appendingPathComponent(Product.name, isDirectory: true)
        }

        try validateStateLocation(stateDirectory, applicationSupport: applicationSupport)
        try ensureSecureDirectory(at: stateDirectory)
        let logsDirectory = stateDirectory.appendingPathComponent("Logs", isDirectory: true)
        try ensureSecureDirectory(at: logsDirectory)

        let rawCommit = bundle.object(forInfoDictionaryKey: "CentLBuildCommit") as? String
        let buildCommit = validatedBuildCommit(rawCommit) ?? "unknown"
        let providerManifestURL = bundle.resourceURL?
            .appendingPathComponent("providers/providers.json", isDirectory: false)
        let existingManifest = providerManifestURL.flatMap {
            fileManager.fileExists(atPath: $0.path) ? $0 : nil
        }
        let providerEnvironment = try loadProviderEnvironment(
            manifestURL: existingManifest,
            resourcesURL: bundle.resourceURL
        )

        return RuntimeContext(
            stateDirectory: stateDirectory,
            diagnosticsURL: logsDirectory.appendingPathComponent("launcher.log", isDirectory: false),
            buildCommit: buildCommit,
            providerManifestURL: existingManifest,
            providerEnvironment: providerEnvironment
        )
    }

    private static func validateStateLocation(
        _ stateDirectory: URL,
        applicationSupport: URL
    ) throws {
        let path = stateDirectory.path
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true).standardizedFileURL.path
        let foundationRoot = applicationSupport
            .appendingPathComponent(Product.organization, isDirectory: true)
            .standardizedFileURL.path
        let forbidden = Set([
            "/", "/Applications", "/Library", "/System", "/Users",
            "/bin", "/etc", "/private", "/private/tmp", "/sbin", "/tmp", "/usr", "/var",
            home, applicationSupport.path, foundationRoot,
        ])
        guard !forbidden.contains(path) else {
            throw StateDirectoryError(message: "CENTL26_STATE_DIR is too broad or reserved: \(path)")
        }

        let pathComponents = stateDirectory.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else {
            throw StateDirectoryError(message: "CENTL26_STATE_DIR must identify a dedicated application directory.")
        }
        if path.hasPrefix(home + "/") {
            let relative = String(path.dropFirst(home.count + 1))
            let relativeComponents = relative.split(separator: "/")
            guard relativeComponents.count >= 2 else {
                throw StateDirectoryError(message: "CENTL26_STATE_DIR may not replace a broad home-directory child: \(path)")
            }
        }
    }

    /// Opens every existing component without following symlinks. Missing
    /// components are created privately; only a newly created leaf is chmodded.
    private static func ensureSecureDirectory(at directory: URL) throws {
        let components = directory.pathComponents.filter { $0 != "/" }
        var parentDescriptor = Darwin.open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard parentDescriptor >= 0 else {
            throw posixError(operation: "open", path: "/", code: errno)
        }
        defer { Darwin.close(parentDescriptor) }

        var traversed = ""
        for (index, component) in components.enumerated() {
            traversed += "/" + component
            var created = false
            var childDescriptor = component.withCString {
                Darwin.openat(parentDescriptor, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            }
            if childDescriptor < 0 && errno == ENOENT {
                let creationResult = component.withCString {
                    Darwin.mkdirat(parentDescriptor, $0, mode_t(0o700))
                }
                if creationResult == 0 {
                    created = true
                } else if errno != EEXIST {
                    throw posixError(operation: "create directory", path: traversed, code: errno)
                }
                childDescriptor = component.withCString {
                    Darwin.openat(parentDescriptor, $0, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
                }
            }
            guard childDescriptor >= 0 else {
                throw posixError(operation: "open directory without following links", path: traversed, code: errno)
            }

            var metadata = stat()
            if Darwin.fstat(childDescriptor, &metadata) != 0 {
                let code = errno
                Darwin.close(childDescriptor)
                throw posixError(operation: "inspect directory", path: traversed, code: code)
            }
            if index == components.count - 1 {
                guard metadata.st_uid == geteuid() else {
                    Darwin.close(childDescriptor)
                    throw StateDirectoryError(message: "CentL26 state directory is not owned by the current user: \(traversed)")
                }
                guard metadata.st_mode & (S_IWGRP | S_IWOTH) == 0 else {
                    Darwin.close(childDescriptor)
                    throw StateDirectoryError(message: "CentL26 state directory is writable by another account: \(traversed)")
                }
                if created && Darwin.fchmod(childDescriptor, mode_t(0o700)) != 0 {
                    let code = errno
                    Darwin.close(childDescriptor)
                    throw posixError(operation: "secure new directory", path: traversed, code: code)
                }
            }

            Darwin.close(parentDescriptor)
            parentDescriptor = childDescriptor
        }
    }

    private static func posixError(operation: String, path: String, code: Int32) -> Error {
        NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(code),
            userInfo: [
                NSLocalizedDescriptionKey: "Could not \(operation) at \(path): \(String(cString: strerror(code)))",
                NSFilePathErrorKey: path,
            ]
        )
    }

    private static func validatedBuildCommit(_ value: String?) -> String? {
        guard let value, !value.isEmpty, value.count <= 64 else { return nil }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars.allSatisfy { allowed.contains($0) } ? value : nil
    }

    private static func loadProviderEnvironment(
        manifestURL: URL?,
        resourcesURL: URL?
    ) throws -> [String: String] {
        guard let manifestURL, let resourcesURL else { return [:] }
        let data = try Data(contentsOf: manifestURL)
        guard
            let document = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let providers = document["providers"] as? [[String: Any]]
        else {
            throw CocoaError(.propertyListReadCorrupt)
        }

        let variableNames = [
            "centl": "CENTL26_CENTL_BIN",
            "centl-sci": "CENTL26_SCI_BIN",
            "centl-chem": "CENTL26_CHEM_BIN",
            "centl-cps": "CENTL26_CPS_BIN",
            "centl-mirage": "CENTL26_MIRAGE_BIN",
        ]
        let providersRoot = resourcesURL
            .appendingPathComponent("providers", isDirectory: true)
            .standardizedFileURL
        var result: [String: String] = [:]

        for provider in providers {
            guard
                let identifier = provider["id"] as? String,
                let relativePath = provider["path"] as? String,
                let variable = variableNames[identifier],
                !relativePath.hasPrefix("/")
            else {
                continue
            }
            let executable = providersRoot
                .appendingPathComponent(relativePath, isDirectory: false)
                .standardizedFileURL
            let rootPrefix = providersRoot.path.hasSuffix("/")
                ? providersRoot.path
                : providersRoot.path + "/"
            guard
                executable.path.hasPrefix(rootPrefix),
                FileManager.default.isExecutableFile(atPath: executable.path)
            else {
                continue
            }
            result[variable] = executable.path
        }
        return result
    }
}

private final class DiagnosticLogger {
    let url: URL

    private let lock = NSLock()
    private let handle: FileHandle
    private let formatter = ISO8601DateFormatter()

    init(url: URL) throws {
        self.url = url
        let fileManager = FileManager.default
        let previousURL = url.deletingLastPathComponent()
            .appendingPathComponent("launcher.previous.log", isDirectory: false)

        var existingMetadata = stat()
        let existingResult = url.path.withCString { Darwin.lstat($0, &existingMetadata) }
        var createsNewFile = existingResult != 0
        if existingResult == 0 {
            guard existingMetadata.st_mode & S_IFMT == S_IFREG else {
                throw StateDirectoryError(message: "CentL26 diagnostics path is not a regular file: \(url.path)")
            }
            guard existingMetadata.st_uid == geteuid() else {
                throw StateDirectoryError(message: "CentL26 diagnostics file is not owned by the current user: \(url.path)")
            }
            guard existingMetadata.st_mode & (S_IRWXG | S_IRWXO) == 0 else {
                throw StateDirectoryError(message: "CentL26 diagnostics file has unsafe permissions: \(url.path)")
            }
        } else if errno != ENOENT {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
        }

        if existingResult == 0 && existingMetadata.st_size > 1_048_576 {
            try? fileManager.removeItem(at: previousURL)
            try fileManager.moveItem(at: url, to: previousURL)
            createsNewFile = true
        }

        let descriptor = url.path.withCString {
            Darwin.open($0, O_WRONLY | O_APPEND | O_CREAT | O_NOFOLLOW | O_CLOEXEC, mode_t(0o600))
        }
        guard descriptor >= 0 else {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSFilePathErrorKey: url.path])
        }
        var openedMetadata = stat()
        guard Darwin.fstat(descriptor, &openedMetadata) == 0,
              openedMetadata.st_mode & S_IFMT == S_IFREG,
              openedMetadata.st_uid == geteuid(),
              openedMetadata.st_mode & (S_IRWXG | S_IRWXO) == 0
        else {
            let code = errno == 0 ? EACCES : errno
            Darwin.close(descriptor)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSFilePathErrorKey: url.path])
        }
        if createsNewFile && Darwin.fchmod(descriptor, mode_t(0o600)) != 0 {
            let code = errno
            Darwin.close(descriptor)
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSFilePathErrorKey: url.path])
        }
        handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        record("launcher diagnostics opened")
    }

    deinit {
        try? handle.close()
    }

    func record(_ message: String) {
        let normalized = message.replacingOccurrences(of: "\0", with: "")
        lock.lock()
        defer { lock.unlock() }
        let line = "\(formatter.string(from: Date())) \(normalized)\n"
        if let data = line.data(using: .utf8) {
            try? handle.write(contentsOf: data)
        }
    }

    func recordBackend(_ data: Data) {
        let message = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !message.isEmpty {
            record("backend | \(message)")
        }
    }

    func makeChildOutputHandle() throws -> FileHandle {
        let descriptor = url.path.withCString {
            Darwin.open($0, O_WRONLY | O_APPEND | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(errno),
                userInfo: [NSFilePathErrorKey: url.path]
            )
        }
        var metadata = stat()
        guard Darwin.fstat(descriptor, &metadata) == 0,
              metadata.st_mode & S_IFMT == S_IFREG,
              metadata.st_uid == geteuid(),
              metadata.st_mode & (S_IRWXG | S_IRWXO) == 0
        else {
            let code = errno == 0 ? EACCES : errno
            Darwin.close(descriptor)
            throw NSError(
                domain: NSPOSIXErrorDomain,
                code: Int(code),
                userInfo: [NSFilePathErrorKey: url.path]
            )
        }
        return FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    }
}

private struct BackendConnection {
    let port: UInt16

    var baseURL: URL {
        URL(string: "http://127.0.0.1:\(port)/")!
    }

    var usedFallbackPort: Bool {
        port != Product.preferredPort
    }
}

private struct BackendLaunchError: LocalizedError {
    let summary: String
    let detail: String

    var errorDescription: String? { summary }
}

private final class LockedProbeResult: @unchecked Sendable {
    private let lock = NSLock()
    private var ready = false

    func store(_ value: Bool) {
        lock.lock()
        ready = value
        lock.unlock()
    }

    func load() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return ready
    }
}

private struct HTTPCommandResponse {
    let statusCode: Int
    let body: String
    let setCookie: String?
}

private final class LockedHTTPCommandResult: @unchecked Sendable {
    private let lock = NSLock()
    private var response: HTTPCommandResponse?
    private var failure: String?

    func store(response: HTTPCommandResponse?, failure: String?) {
        lock.lock()
        self.response = response
        self.failure = failure
        lock.unlock()
    }

    func load() -> (HTTPCommandResponse?, String?) {
        lock.lock()
        defer { lock.unlock() }
        return (response, failure)
    }
}

/// Drains both child-process streams so a verbose backend can never block on a
/// full pipe. Only a bounded tail is retained for native error reporting.
private final class OutputCollector {
    let standardOutput = Pipe()
    let standardError = Pipe()

    private let lock = NSLock()
    private var buffer = Data()
    private let maximumBytes = 64 * 1024
    private let logger: DiagnosticLogger

    init(logger: DiagnosticLogger) {
        self.logger = logger
        observe(standardOutput.fileHandleForReading)
        observe(standardError.fileHandleForReading)
    }

    private func observe(_ handle: FileHandle) {
        handle.readabilityHandler = { [weak self] readable in
            let data = readable.availableData
            guard !data.isEmpty else {
                readable.readabilityHandler = nil
                return
            }
            self?.append(data)
            self?.logger.recordBackend(data)
        }
    }

    private func append(_ data: Data) {
        lock.lock()
        buffer.append(data)
        if buffer.count > maximumBytes {
            buffer.removeFirst(buffer.count - maximumBytes)
        }
        lock.unlock()
    }

    func snapshot() -> String {
        lock.lock()
        let copy = buffer
        lock.unlock()
        return String(decoding: copy, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Owns exactly one backend process launched from this application bundle.
/// It never adopts or terminates a process that was already using a port.
private enum PortAvailability {
    case available
    case inUse
    case failed(Int32, String)
}

private final class BackendController {
    private let supervisorURL: URL
    private let backendURL: URL
    private let context: RuntimeContext
    private let logger: DiagnosticLogger
    private let stateLock = NSLock()
    private var activeProcess: Process?
    private var activeOutput: OutputCollector?
    private var stopping = false
    private lazy var probeSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 0.45
        configuration.timeoutIntervalForResource = 0.65
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }()

    var onUnexpectedTermination: ((String) -> Void)?

    init(supervisorURL: URL, backendURL: URL, context: RuntimeContext, logger: DiagnosticLogger) {
        self.supervisorURL = supervisorURL
        self.backendURL = backendURL
        self.context = context
        self.logger = logger
    }

    deinit {
        stop()
        probeSession.invalidateAndCancel()
    }

    func start() -> Result<BackendConnection, BackendLaunchError> {
        guard FileManager.default.isExecutableFile(atPath: supervisorURL.path) else {
            return .failure(BackendLaunchError(
                summary: "The CentL26 process supervisor is missing.",
                detail: "Expected an executable at:\n\(supervisorURL.path)\n\nRebuild the application bundle from the repository.\n\nDiagnostics: \(logger.url.path)"
            ))
        }
        guard FileManager.default.isExecutableFile(atPath: backendURL.path) else {
            return .failure(BackendLaunchError(
                summary: "The CentL26 computation service is missing.",
                detail: "Expected an executable at:\n\(backendURL.path)\n\nRebuild the application bundle from the repository.\n\nDiagnostics: \(logger.url.path)"
            ))
        }

        stateLock.lock()
        let cancelled = stopping
        stateLock.unlock()
        guard !cancelled else {
            return .failure(BackendLaunchError(
                summary: "CentL26 startup was cancelled.",
                detail: "The application is already shutting down."
            ))
        }

        var attemptDetails: [String] = []
        let lastPort = Int(Product.preferredPort) + Product.fallbackPortCount
        logger.record("starting backend; preferred loopback port \(Product.preferredPort)")

        for rawPort in Int(Product.preferredPort)...lastPort {
            let port = UInt16(rawPort)
            switch portAvailability(port) {
            case .available:
                break
            case .inUse:
                attemptDetails.append("Port \(port): already in use")
                logger.record("port \(port) is already in use")
                continue
            case .failed(let code, let message):
                logger.record("loopback preflight failed on port \(port): \(message) (errno \(code))")
                return .failure(BackendLaunchError(
                    summary: "CentL26 cannot access its private loopback service.",
                    detail: "The operating system refused a loopback bind on 127.0.0.1:\(port): \(message) (errno \(code)).\n\nDiagnostics: \(logger.url.path)"
                ))
            }

            let process = Process()
            let output = OutputCollector(logger: logger)
            process.executableURL = supervisorURL
            process.arguments = [backendURL.path, String(port)]
            process.currentDirectoryURL = backendURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()

            var environment: [String: String] = [
                "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                "HOME": NSHomeDirectory(),
                "TMPDIR": NSTemporaryDirectory(),
                "LC_ALL": "C",
                "CENTL_BIND_HOST": "127.0.0.1",
                "CENTL26_STATE_DIR": context.stateDirectory.path,
                "CENTL_BUILD_COMMIT": context.buildCommit,
                "CENTL26_PRODUCT_VERSION": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            ]
            if let manifest = context.providerManifestURL {
                environment["CENTL26_PROVIDER_MANIFEST"] = manifest.path
            }
            for (name, value) in context.providerEnvironment {
                environment[name] = value
            }
            process.environment = environment
            process.standardOutput = output.standardOutput
            process.standardError = output.standardError

            do {
                try process.run()
                logger.record("supervisor \(process.processIdentifier) launched for port \(port)")
            } catch {
                logger.record("supervisor launch failed: \(error.localizedDescription)")
                return .failure(BackendLaunchError(
                    summary: "CentL26 could not launch its computation service.",
                    detail: "\(error.localizedDescription)\n\nDiagnostics: \(logger.url.path)"
                ))
            }

            stateLock.lock()
            activeProcess = process
            activeOutput = output
            let shouldStop = stopping
            stateLock.unlock()

            if shouldStop {
                terminateAndWait(process)
                return .failure(BackendLaunchError(
                    summary: "CentL26 startup was cancelled.",
                    detail: "The application is already shutting down."
                ))
            }

            let deadline = Date().addingTimeInterval(5.0)
            var ready = false
            while Date() < deadline && process.isRunning {
                if readinessProbe(port: port) {
                    // A different process may have answered during the small
                    // interval in which our child failed to bind. Accept the
                    // origin only while the child we own is still alive.
                    Thread.sleep(forTimeInterval: 0.08)
                    if process.isRunning {
                        ready = true
                        break
                    }
                }
                Thread.sleep(forTimeInterval: 0.06)
            }

            if ready {
                process.terminationHandler = { [weak self] endedProcess in
                    self?.processTerminated(endedProcess)
                }
                logger.record("backend ready on 127.0.0.1:\(port)")
                return .success(BackendConnection(port: port))
            }

            if process.isRunning {
                terminateAndWait(process)
                let diagnostic = output.snapshot()
                clearActiveProcess(ifMatching: process)
                return .failure(BackendLaunchError(
                    summary: "The CentL26 computation service did not become ready.",
                    detail: diagnostic.isEmpty
                        ? "The service started on loopback port \(port), but its readiness endpoint did not answer within five seconds.\n\nDiagnostics: \(logger.url.path)"
                        : "\(diagnostic)\n\nDiagnostics: \(logger.url.path)"
                ))
            }

            // Binding an occupied port makes centl26 exit immediately. Move
            // through a deliberately small, visible fallback range; do not
            // connect to whichever process already owns the original port.
            Thread.sleep(forTimeInterval: 0.04)
            let diagnostic = output.snapshot()
            clearActiveProcess(ifMatching: process)
            if diagnostic.localizedCaseInsensitiveContains("address already in use") {
                attemptDetails.append("Port \(port): became occupied during startup")
                logger.record("port \(port) became occupied during startup")
                continue
            }
            logger.record("service exited during startup on port \(port): \(diagnostic)")
            return .failure(BackendLaunchError(
                summary: "The CentL26 computation service exited during startup.",
                detail: diagnostic.isEmpty
                    ? "The bundled service exited before readiness.\n\nDiagnostics: \(logger.url.path)"
                    : "\(diagnostic)\n\nDiagnostics: \(logger.url.path)"
            ))
        }

        let attemptedRange = "\(Product.preferredPort)\u{2013}\(lastPort)"
        return .failure(BackendLaunchError(
            summary: "CentL26 could not reserve a local computation port.",
            detail: "Ports \(attemptedRange) were attempted on 127.0.0.1. Quit the application currently using that range and try again.\n\n" + attemptDetails.joined(separator: "\n") + "\n\nDiagnostics: \(logger.url.path)"
        ))
    }

    func stop() {
        stateLock.lock()
        stopping = true
        let process = activeProcess
        activeProcess = nil
        activeOutput = nil
        stateLock.unlock()

        if let process {
            logger.record("stopping supervisor \(process.processIdentifier)")
            terminateAndWait(process)
        }
    }

    private func readinessProbe(port: UInt16) -> Bool {
        guard let url = URL(string: "http://127.0.0.1:\(port)\(Product.readinessPath)") else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 0.45
        request.setValue("close", forHTTPHeaderField: "Connection")

        let semaphore = DispatchSemaphore(value: 0)
        let result = LockedProbeResult()
        let task = probeSession.dataTask(with: request) { data, response, _ in
            defer { semaphore.signal() }
            guard
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data
            else {
                return
            }
            let marker = String(decoding: data, as: UTF8.self)
            guard marker.hasPrefix("centl26 ") || marker.hasPrefix("centl-lab ") else {
                return
            }
            result.store(true)
        }
        task.resume()

        let completed = semaphore.wait(timeout: .now() + .milliseconds(700)) == .success
        if !completed {
            task.cancel()
        }
        return completed && result.load()
    }

    /// A preflight bind prevents the launcher from accidentally treating a
    /// readiness response from an already-running, unrelated service as its
    /// own. centl26 performs the authoritative bind immediately afterward.
    private func portAvailability(_ port: UInt16) -> PortAvailability {
        let descriptor = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else {
            let code = errno
            return .failed(code, String(cString: strerror(code)))
        }
        defer { Darwin.close(descriptor) }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                Darwin.bind(
                    descriptor,
                    socketAddress,
                    socklen_t(MemoryLayout<sockaddr_in>.size)
                ) == 0
            }
        }
        if result {
            return .available
        }
        let code = errno
        if code == EADDRINUSE {
            return .inUse
        }
        return .failed(code, String(cString: strerror(code)))
    }

    private func clearActiveProcess(ifMatching candidate: Process) {
        stateLock.lock()
        if activeProcess === candidate {
            activeProcess = nil
            activeOutput = nil
        }
        stateLock.unlock()
    }

    private func processTerminated(_ process: Process) {
        stateLock.lock()
        let wasStopping = stopping
        let wasActive = activeProcess === process
        let diagnostic = activeOutput?.snapshot() ?? ""
        if wasActive {
            activeProcess = nil
            activeOutput = nil
        }
        let callback = onUnexpectedTermination
        stateLock.unlock()

        guard wasActive && !wasStopping else { return }
        let reason = diagnostic.isEmpty
            ? "The local computation service exited with status \(process.terminationStatus)."
            : diagnostic
        logger.record("supervisor exited unexpectedly with status \(process.terminationStatus): \(reason)")
        DispatchQueue.main.async {
            callback?(reason)
        }
    }

    private func terminateAndWait(_ process: Process) {
        guard process.isRunning else { return }
        process.terminate()

        let deadline = Date().addingTimeInterval(1.5)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.04)
        }
        if process.isRunning {
            Darwin.kill(process.processIdentifier, SIGKILL)
            let killDeadline = Date().addingTimeInterval(0.5)
            while process.isRunning && Date() < killDeadline {
                Thread.sleep(forTimeInterval: 0.02)
            }
        }
    }
}

private final class StartupView: NSView {
    private let statusLabel = NSTextField(labelWithString: "Starting the local computation service\u{2026}")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let mark = NSTextField(labelWithString: "FCF")
        mark.font = .systemFont(ofSize: 11, weight: .semibold)
        mark.textColor = .controlAccentColor
        mark.alignment = .center

        let title = NSTextField(labelWithString: Product.name)
        title.font = .systemFont(ofSize: 32, weight: .semibold)
        title.textColor = .labelColor
        title.alignment = .center

        let organization = NSTextField(labelWithString: Product.organization)
        organization.font = .systemFont(ofSize: 12, weight: .medium)
        organization.textColor = .secondaryLabelColor
        organization.alignment = .center

        let progress = NSProgressIndicator()
        progress.style = .spinning
        progress.controlSize = .small
        progress.startAnimation(nil)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .tertiaryLabelColor
        statusLabel.alignment = .center

        let stack = NSStackView(views: [mark, title, organization, progress, statusLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 9
        stack.setCustomSpacing(2, after: title)
        stack.setCustomSpacing(25, after: organization)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -12),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -28),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStatus(_ message: String) {
        statusLabel.stringValue = message
    }
}

private final class ErrorView: NSView {
    init(error: BackendLaunchError, retry: @escaping () -> Void) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let badge = NSTextField(labelWithString: "CENTL26")
        badge.font = .systemFont(ofSize: 11, weight: .semibold)
        badge.textColor = .controlAccentColor

        let title = NSTextField(labelWithString: error.summary)
        title.font = .systemFont(ofSize: 22, weight: .semibold)
        title.textColor = .labelColor
        title.alignment = .center
        title.maximumNumberOfLines = 2

        let explanation = NSTextField(wrappingLabelWithString: error.detail)
        explanation.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        explanation.textColor = .secondaryLabelColor
        explanation.alignment = .left
        explanation.maximumNumberOfLines = 10
        explanation.lineBreakMode = .byTruncatingTail
        explanation.widthAnchor.constraint(lessThanOrEqualToConstant: 620).isActive = true

        let retryButton = NSButton(title: "Try Again", target: nil, action: nil)
        retryButton.keyEquivalent = "\r"
        retryButton.bezelStyle = .rounded
        retryButton.target = ClosureAction.shared
        retryButton.action = #selector(ClosureAction.invoke(_:))
        ClosureAction.shared.install(for: retryButton, action: retry)

        let quitButton = NSButton(title: "Quit CentL26", target: NSApp, action: #selector(NSApplication.terminate(_:)))
        quitButton.bezelStyle = .rounded

        let buttons = NSStackView(views: [quitButton, retryButton])
        buttons.orientation = .horizontal
        buttons.spacing = 10

        let stack = NSStackView(views: [badge, title, explanation, buttons])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 15
        stack.setCustomSpacing(5, after: badge)
        stack.setCustomSpacing(24, after: explanation)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 42),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -42),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Keeps closure-backed button actions alive without introducing a framework.
private final class ClosureAction: NSObject {
    static let shared = ClosureAction()
    private var actions: [ObjectIdentifier: () -> Void] = [:]

    func install(for control: NSControl, action: @escaping () -> Void) {
        actions[ObjectIdentifier(control)] = action
    }

    @objc func invoke(_ sender: NSControl) {
        actions[ObjectIdentifier(sender)]?()
    }
}

private final class WorkspaceNavigationDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    private let port: UInt16
    var onLoadFailure: ((Error) -> Void)?

    init(port: UInt16) {
        self.port = port
    }

    private func permits(_ url: URL?) -> Bool {
        guard let url else { return false }
        if url.absoluteString == "about:blank" { return true }
        return url.scheme == "http"
            && url.host == "127.0.0.1"
            && (url.port ?? 80) == Int(port)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if permits(navigationAction.request.url) {
            decisionHandler(.allow)
        } else {
            NSSound.beep()
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if permits(navigationAction.request.url) {
                webView.load(navigationAction.request)
            } else if let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
            }
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard permits(frame.request.url), let window = webView.window else {
            completionHandler(false)
            return
        }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = Product.name
        alert.informativeText = message
        let confirmsNotebookClear = message == "Clear this CentL26 notebook and its saved receipts?"
        alert.addButton(withTitle: confirmsNotebookClear ? "Clear Notebook" : "OK")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { response in
            completionHandler(response == .alertFirstButtonReturn)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onLoadFailure?(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onLoadFailure?(error)
    }
}

private final class WorkspaceController {
    let webView: WKWebView
    private let navigationDelegate: WorkspaceNavigationDelegate
    private let updateMessageHandler: CentL26UpdateMessageHandler
    private let baseURL: URL

    init(
        connection: BackendConnection,
        onLoadFailure: @escaping (Error) -> Void,
        onUpdateRequested: @escaping () -> Void
    ) {
        baseURL = connection.baseURL
        navigationDelegate = WorkspaceNavigationDelegate(port: connection.port)
        updateMessageHandler = CentL26UpdateMessageHandler(
            port: connection.port,
            onCheck: onUpdateRequested
        )

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.applicationNameForUserAgent = Product.name
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.userContentController.add(
            updateMessageHandler,
            name: CentL26UpdateContract.messageHandlerName
        )

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = navigationDelegate
        webView.uiDelegate = navigationDelegate
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsMagnification = true
        webView.magnification = 1.0
        webView.autoresizingMask = [.width, .height]
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.white.cgColor

        navigationDelegate.onLoadFailure = onLoadFailure
        reload()
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: CentL26UpdateContract.messageHandlerName
        )
    }

    func reload() {
        var request = URLRequest(url: baseURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }

    func focusNewCell() {
        webView.evaluateJavaScript("document.querySelector('[data-new-computation]')?.click()")
    }

    func runActiveCell() {
        webView.evaluateJavaScript("document.querySelector('.composer-run, form button[type=submit]')?.click()")
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private var startupView: StartupView!
    private var workspaceController: WorkspaceController?
    private var backend: BackendController!
    private var updateController: CentL26UpdateController?
    private var launchInProgress = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.global(qos: .utility).async {
            CentL26UpdateContract.cleanupStagingDirectories(near: Bundle.main.bundleURL)
        }
        configureWindow()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        prepareBackendAndLaunch()
    }

    func applicationWillTerminate(_ notification: Notification) {
        backend?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window.makeKeyAndOrderFront(nil)
        }
        return true
    }

    @objc func reloadWorkspace(_ sender: Any?) {
        workspaceController?.reload()
    }

    @objc func focusNewCell(_ sender: Any?) {
        workspaceController?.focusNewCell()
    }

    @objc func runActiveCell(_ sender: Any?) {
        workspaceController?.runActiveCell()
    }

    @objc func checkForUpdates(_ sender: Any?) {
        guard let updateController else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Automatic Updates Unavailable"
            alert.informativeText = "CentL26 has not finished preparing its native update service."
            alert.addButton(withTitle: "OK")
            if let window, window.attachedSheet == nil {
                alert.beginSheetModal(for: window)
            } else {
                NSSound.beep()
            }
            return
        }
        updateController.checkForUpdates()
    }

    private func prepareBackendAndLaunch() {
        do {
            guard let resources = Bundle.main.resourceURL else {
                throw BackendLaunchError(
                    summary: "CentL26 could not locate its application resources.",
                    detail: "The application bundle is incomplete."
                )
            }
            let context = try RuntimeContext.prepare()
            let logger = try DiagnosticLogger(url: context.diagnosticsURL)
            logger.record("CentL26 \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown") build \(context.buildCommit)")

            updateController = CentL26UpdateController(
                bundle: .main,
                presentingWindow: { [weak self] in self?.window },
                beforeRelaunch: { [weak self] in self?.backend?.stop() },
                logger: { [weak logger] message in logger?.record("updater | \(message)") },
                helperOutputHandle: { try logger.makeChildOutputHandle() }
            )

            let backendURL = resources.appendingPathComponent("bin/centl26", isDirectory: false)
            let supervisorURL = Bundle.main.bundleURL
                .appendingPathComponent("Contents/Helpers/centl26-supervisor", isDirectory: false)
            backend = BackendController(
                supervisorURL: supervisorURL,
                backendURL: backendURL,
                context: context,
                logger: logger
            )
            backend.onUnexpectedTermination = { [weak self] detail in
                self?.showError(BackendLaunchError(
                    summary: "The local computation service stopped unexpectedly.",
                    detail: detail
                ))
            }
            launchBackend()
        } catch let error as BackendLaunchError {
            showError(error, retry: { [weak self] in self?.prepareBackendAndLaunch() })
        } catch {
            showError(BackendLaunchError(
                summary: "CentL26 could not prepare its local workspace.",
                detail: "\(error.localizedDescription)\n\nExpected state location: ~/Library/Application Support/Free Computation Foundation/CentL26"
            ), retry: { [weak self] in self?.prepareBackendAndLaunch() })
        }
    }

    private func configureWindow() {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let width = max(780, min(1440, visibleFrame.width - 48))
        let height = max(580, min(940, visibleFrame.height - 48))
        let frame = NSRect(origin: .zero, size: NSSize(width: width, height: height))

        window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = Product.name
        window.subtitle = Product.organization
        window.minSize = NSSize(width: 780, height: 580)
        window.collectionBehavior = [.fullScreenPrimary]
        window.tabbingMode = .disallowed
        window.isReleasedWhenClosed = false
        window.delegate = self

        let restored = window.setFrameUsingName("CentL26MainWindow")
        window.setFrameAutosaveName("CentL26MainWindow")
        if !restored {
            window.center()
        }

        startupView = StartupView(frame: window.contentView?.bounds ?? .zero)
        startupView.autoresizingMask = [.width, .height]
        window.contentView = startupView
    }

    private func launchBackend() {
        guard !launchInProgress else { return }
        launchInProgress = true
        workspaceController = nil

        startupView = StartupView(frame: window.contentView?.bounds ?? .zero)
        startupView.autoresizingMask = [.width, .height]
        window.contentView = startupView
        window.subtitle = Product.organization

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result = self.backend.start()
            DispatchQueue.main.async { [weak self] in
                self?.finishBackendLaunch(result)
            }
        }
    }

    private func finishBackendLaunch(_ result: Result<BackendConnection, BackendLaunchError>) {
        launchInProgress = false
        switch result {
        case .success(let connection):
            showWorkspace(connection)
        case .failure(let error):
            showError(error)
        }
    }

    private func showWorkspace(_ connection: BackendConnection) {
        window.subtitle = connection.usedFallbackPort
            ? "Local kernel \u{00b7} fallback port \(connection.port)"
            : "Local kernel \u{00b7} 127.0.0.1:\(connection.port)"

        let workspace = WorkspaceController(
            connection: connection,
            onLoadFailure: { [weak self] error in self?.showLoadFailure(error) },
            onUpdateRequested: { [weak self] in self?.checkForUpdates(nil) }
        )
        workspace.webView.frame = window.contentView?.bounds ?? .zero
        window.contentView = workspace.webView
        workspaceController = workspace
        window.makeFirstResponder(workspace.webView)
    }

    private func showError(_ error: BackendLaunchError, retry: (() -> Void)? = nil) {
        launchInProgress = false
        workspaceController = nil
        window.subtitle = "Local kernel unavailable"
        let retryAction = retry ?? { [weak self] in self?.launchBackend() }
        let errorView = ErrorView(error: error, retry: retryAction)
        errorView.frame = window.contentView?.bounds ?? .zero
        errorView.autoresizingMask = [.width, .height]
        window.contentView = errorView
        window.makeKeyAndOrderFront(nil)
    }

    private func showLoadFailure(_ error: Error) {
        guard window.isVisible else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "CentL26 could not load its local workspace."
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "Reload")
        alert.addButton(withTitle: "Quit")
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .alertFirstButtonReturn {
                self?.workspaceController?.reload()
            } else {
                NSApp.terminate(nil)
            }
        }
    }
}

private enum MainMenu {
    static func install(delegate: AppDelegate) {
        let main = NSMenu(title: "Main Menu")

        let applicationItem = NSMenuItem()
        main.addItem(applicationItem)
        let application = NSMenu(title: Product.name)
        applicationItem.submenu = application
        application.addItem(withTitle: "About \(Product.name)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        let updates = application.addItem(withTitle: "Check for Updates…", action: #selector(AppDelegate.checkForUpdates(_:)), keyEquivalent: "")
        updates.target = delegate
        application.addItem(.separator())

        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let services = NSMenu(title: "Services")
        servicesItem.submenu = services
        NSApp.servicesMenu = services
        application.addItem(servicesItem)
        application.addItem(.separator())
        application.addItem(withTitle: "Hide \(Product.name)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = application.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        application.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        application.addItem(.separator())
        application.addItem(withTitle: "Quit \(Product.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let fileItem = NSMenuItem()
        main.addItem(fileItem)
        let file = NSMenu(title: "File")
        fileItem.submenu = file
        let newCell = file.addItem(withTitle: "New Computation", action: #selector(AppDelegate.focusNewCell(_:)), keyEquivalent: "n")
        newCell.target = delegate
        file.addItem(.separator())
        file.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        let editItem = NSMenuItem()
        main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        editItem.submenu = edit
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let viewItem = NSMenuItem()
        main.addItem(viewItem)
        let view = NSMenu(title: "View")
        viewItem.submenu = view
        let reload = view.addItem(withTitle: "Reload Workspace", action: #selector(AppDelegate.reloadWorkspace(_:)), keyEquivalent: "r")
        reload.target = delegate
        view.addItem(.separator())
        view.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
            .keyEquivalentModifierMask = [.command, .control]

        let runItem = NSMenuItem()
        main.addItem(runItem)
        let run = NSMenu(title: "Run")
        runItem.submenu = run
        let runActive = run.addItem(withTitle: "Run Active Cell", action: #selector(AppDelegate.runActiveCell(_:)), keyEquivalent: "\r")
        runActive.keyEquivalentModifierMask = [.command]
        runActive.target = delegate

        let windowItem = NSMenuItem()
        main.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window")
        windowItem.submenu = windowMenu
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenu.addItem(.separator())
        windowMenu.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = main
    }
}

private enum CommandLineMode {
    private static func controller() throws -> (BackendController, RuntimeContext) {
        guard let resources = Bundle.main.resourceURL else {
            throw BackendLaunchError(
                summary: "Application resources unavailable.",
                detail: "The CentL26 bundle is incomplete."
            )
        }
        let context = try RuntimeContext.prepare()
        let logger = try DiagnosticLogger(url: context.diagnosticsURL)
        let backendURL = resources.appendingPathComponent("bin/centl26", isDirectory: false)
        let supervisorURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Helpers/centl26-supervisor", isDirectory: false)
        return (
            BackendController(
                supervisorURL: supervisorURL,
                backendURL: backendURL,
                context: context,
                logger: logger
            ),
            context
        )
    }

    static func runSelfTest() -> Never {
        let backend: BackendController
        let context: RuntimeContext
        do {
            try validateFormEncoding()
            print("CentL26 self-test: form encoding contract passed")
            (backend, context) = try controller()
        } catch {
            fputs("CentL26 self-test setup failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
        guard context.providerEnvironment["CENTL26_CENTL_BIN"] != nil else {
            fputs("CentL26 self-test failed: centl is not declared in the provider manifest.\n", stderr)
            exit(EXIT_FAILURE)
        }
        switch backend.start() {
        case .success(let connection):
            print("CentL26 self-test: ready at \(connection.baseURL.absoluteString)")
            do {
                let cookie = try initialSessionCookie(for: connection)
                let result = try submit(command: "approx(pi, 50)", to: connection, cookie: cookie)
                if result.contains("error-result") {
                    throw BackendLaunchError(
                        summary: "The packaged rigorous-numerics request was rejected.",
                        detail: "approx(pi, 50) returned an error result."
                    )
                }
                for marker in [
                    "approx(pi, 50)",
                    "kind-bounded",
                    "3.141592653589793238462643383279502884197169399375",
                ] where !result.contains(marker) {
                    throw BackendLaunchError(
                        summary: "The packaged rigorous-numerics response was incomplete.",
                        detail: "Missing marker: \(marker)"
                    )
                }
                backend.stop()
                print("CentL26 self-test: rigorous numerics passed")
                print("CentL26 self-test: backend terminated cleanly")
                exit(EXIT_SUCCESS)
            } catch {
                backend.stop()
                fputs("CentL26 self-test failed: \(error.localizedDescription)\n", stderr)
                exit(EXIT_FAILURE)
            }
        case .failure(let error):
            fputs("CentL26 self-test failed: \(error.summary)\n\(error.detail)\n", stderr)
            backend.stop()
            exit(EXIT_FAILURE)
        }
    }

    private static func perform(_ request: URLRequest) throws -> HTTPCommandResponse {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 4.0
        configuration.timeoutIntervalForResource = 5.0
        let session = URLSession(configuration: configuration)
        let semaphore = DispatchSemaphore(value: 0)
        let result = LockedHTTPCommandResult()
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error {
                result.store(response: nil, failure: error.localizedDescription)
                return
            }
            guard let response = response as? HTTPURLResponse, let data else {
                result.store(response: nil, failure: "The local service returned no HTTP response.")
                return
            }
            result.store(
                response: HTTPCommandResponse(
                    statusCode: response.statusCode,
                    body: String(decoding: data, as: UTF8.self),
                    setCookie: response.value(forHTTPHeaderField: "Set-Cookie")
                ),
                failure: nil
            )
        }
        task.resume()
        guard semaphore.wait(timeout: .now() + .seconds(6)) == .success else {
            task.cancel()
            session.invalidateAndCancel()
            throw BackendLaunchError(
                summary: "The packaged HTTP smoke request timed out.",
                detail: request.url?.absoluteString ?? "unknown URL"
            )
        }
        session.finishTasksAndInvalidate()
        let (response, failure) = result.load()
        if let failure {
            throw BackendLaunchError(
                summary: "The packaged HTTP smoke request failed.",
                detail: failure
            )
        }
        guard let response else {
            throw BackendLaunchError(
                summary: "The packaged HTTP smoke request returned no response.",
                detail: request.url?.absoluteString ?? "unknown URL"
            )
        }
        return response
    }

    private static func initialSessionCookie(for connection: BackendConnection) throws -> String {
        var request = URLRequest(url: connection.baseURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 4.0
        request.setValue("close", forHTTPHeaderField: "Connection")
        let response = try perform(request)
        guard response.statusCode == 200, let header = response.setCookie else {
            throw BackendLaunchError(
                summary: "The packaged service did not mint its local session cookie.",
                detail: "Initial GET returned HTTP \(response.statusCode)."
            )
        }
        let cookie = header.split(separator: ";", maxSplits: 1).first.map(String.init) ?? ""
        let prefix = "centl26_sid="
        guard cookie.hasPrefix(prefix) else {
            throw BackendLaunchError(
                summary: "The packaged service returned an unexpected session cookie.",
                detail: header
            )
        }
        let token = cookie.dropFirst(prefix.count)
        let hexadecimal = CharacterSet(charactersIn: "0123456789abcdef")
        guard token.count == 32, token.unicodeScalars.allSatisfy({ hexadecimal.contains($0) }) else {
            throw BackendLaunchError(
                summary: "The packaged service returned an invalid session token.",
                detail: "The token did not match the CentL26 session format."
            )
        }
        return cookie
    }

    private static func formEncode(_ value: String) -> String {
        var encoded = String()
        for byte in value.utf8 {
            switch byte {
            case 0x2A, 0x2D, 0x2E, 0x30...0x39, 0x41...0x5A, 0x5F, 0x61...0x7A:
                encoded.append(Character(UnicodeScalar(byte)))
            case 0x20:
                encoded.append("+")
            default:
                encoded.append(String(format: "%%%02X", byte))
            }
        }
        return encoded
    }

    private static func formBody(_ fields: [(String, String)]) -> Data {
        let encoded = fields
            .map { "\(formEncode($0.0))=\(formEncode($0.1))" }
            .joined(separator: "&")
        return Data(encoded.utf8)
    }

    private static func validateFormEncoding() throws {
        let encoded = String(
            decoding: formBody([
                ("cmd", "chem balance Fe + O2 -> Fe2O3"),
                ("note", "π & x=2"),
            ]),
            as: UTF8.self
        )
        let expected = "cmd=chem+balance+Fe+%2B+O2+-%3E+Fe2O3&note=%CF%80+%26+x%3D2"
        guard encoded == expected else {
            throw BackendLaunchError(
                summary: "The application form encoder failed its contract test.",
                detail: "Expected \(expected), received \(encoded)."
            )
        }
    }

    private static func submit(
        command: String,
        to connection: BackendConnection,
        cookie: String
    ) throws -> String {
        let endpoint = connection.baseURL.appendingPathComponent("api/run", isDirectory: false)
        let encoded = formBody([
            ("lab_action", "calculate"),
            ("cmd", command),
        ])

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = encoded
        request.timeoutInterval = 4.0
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("http://127.0.0.1:\(connection.port)", forHTTPHeaderField: "Origin")
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        request.setValue("close", forHTTPHeaderField: "Connection")
        let response = try perform(request)
        guard response.statusCode == 200 else {
            throw BackendLaunchError(
                summary: "The packaged smoke command returned an unexpected response.",
                detail: "\(command): HTTP \(response.statusCode)"
            )
        }
        return response.body
    }

    static func runChemistrySelfTest() -> Never {
        let backend: BackendController
        let context: RuntimeContext
        do {
            (backend, context) = try controller()
        } catch {
            fputs("CentL26 chemistry self-test setup failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
        guard context.providerEnvironment["CENTL26_CHEM_BIN"] != nil else {
            fputs("CentL26 chemistry self-test failed: centl-chem is not declared in the provider manifest.\n", stderr)
            exit(EXIT_FAILURE)
        }

        let connection: BackendConnection
        switch backend.start() {
        case .success(let readyConnection):
            connection = readyConnection
        case .failure(let error):
            fputs("CentL26 chemistry self-test failed: \(error.summary)\n\(error.detail)\n", stderr)
            backend.stop()
            exit(EXIT_FAILURE)
        }

        do {
            let cookie = try initialSessionCookie(for: connection)
            let atomResult = try submit(command: "chem atoms Ca(OH)2", to: connection, cookie: cookie)
            for marker in ["Ca(OH)2", "Ca=1", "H=2", "O=2"] where !atomResult.contains(marker) {
                throw BackendLaunchError(
                    summary: "The packaged atom-count response was incomplete.",
                    detail: "Missing marker: \(marker)"
                )
            }
            let balanceResult = try submit(
                command: "chem balance Fe + O2 -> Fe2O3",
                to: connection,
                cookie: cookie
            )
            for marker in ["4 Fe + 3 O2", "2 Fe2O3", "Atom conservation verified"] where !balanceResult.contains(marker) {
                throw BackendLaunchError(
                    summary: "The packaged reaction-balance response was incomplete.",
                    detail: "Missing marker: \(marker)"
                )
            }
            backend.stop()
            print("CentL26 chemistry self-test: atoms and balance passed")
            print("CentL26 chemistry self-test: backend terminated cleanly")
            exit(EXIT_SUCCESS)
        } catch {
            backend.stop()
            fputs("CentL26 chemistry self-test failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    static func printDiagnostics() -> Never {
        do {
            let (_, context) = try controller()
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
            let identifier = Bundle.main.bundleIdentifier ?? "unknown"
            print("product: \(Product.name) \(version)")
            print("bundle_identifier: \(identifier)")
            print("bundle: \(Bundle.main.bundleURL.path)")
            print("build_commit: \(context.buildCommit)")
            print("state_directory: \(context.stateDirectory.path)")
            print("diagnostics: \(context.diagnosticsURL.path)")
            print("provider_manifest: \(context.providerManifestURL?.path ?? "none")")
            print("bundled_provider_paths: \(context.providerEnvironment.count)")
            exit(EXIT_SUCCESS)
        } catch {
            fputs("CentL26 diagnostics failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }

    static func runUpdaterSelfTest() -> Never {
        do {
            try CentL26UpdateContract.runSelfTest(bundle: .main)
            print("CentL26 updater self-test: release and installer contracts passed")
            exit(EXIT_SUCCESS)
        } catch {
            fputs("CentL26 updater self-test failed: \(error.localizedDescription)\n", stderr)
            exit(EXIT_FAILURE)
        }
    }
}

@main
private enum CentL26EntryPoint {
    static func main() {
        if CommandLine.arguments.contains("--self-test") {
            CommandLineMode.runSelfTest()
        }
        if CommandLine.arguments.contains("--diagnostics") {
            CommandLineMode.printDiagnostics()
        }
        if CommandLine.arguments.contains("--self-test-chemistry") {
            CommandLineMode.runChemistrySelfTest()
        }
        if CommandLine.arguments.contains("--self-test-updater") {
            CommandLineMode.runUpdaterSelfTest()
        }

        let application = NSApplication.shared
        application.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        application.delegate = delegate
        MainMenu.install(delegate: delegate)
        application.run()
        _ = delegate
    }
}
