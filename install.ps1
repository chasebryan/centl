[CmdletBinding()]
param(
    [string] $Version = "latest",
    [string] $ReleaseBaseUrl = $env:CENTL_RELEASE_BASE_URL,
    [string] $Prefix = $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "Programs\CENTL" }),
    [string] $Archive,
    [switch] $NoPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Repository = "chasebryan/centl"

if (-not $Prefix) {
    throw "centl install: LOCALAPPDATA is not set; use -Prefix PATH"
}
if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    throw "centl install: prebuilt Windows releases currently support x86_64 only"
}
if ($Archive -and $ReleaseBaseUrl) {
    throw "centl install: -Archive and -ReleaseBaseUrl are mutually exclusive"
}

$Prefix = [IO.Path]::GetFullPath($Prefix)
$Asset = "centl-windows-x86_64.zip"
$Temporary = Join-Path ([IO.Path]::GetTempPath()) ("centl-install-" + [Guid]::NewGuid().ToString("N"))
$DownloadedArchive = Join-Path $Temporary $Asset
$Checksum = "$DownloadedArchive.sha256"
$Staging = $null
New-Item -ItemType Directory -Path $Temporary | Out-Null

try {
    if ($Archive) {
        $Archive = [IO.Path]::GetFullPath($Archive)
        if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) {
            throw "centl install: archive not found: $Archive"
        }
        if (-not (Test-Path -LiteralPath "$Archive.sha256" -PathType Leaf)) {
            throw "centl install: checksum not found: $Archive.sha256"
        }
        Copy-Item -LiteralPath $Archive -Destination $DownloadedArchive
        Copy-Item -LiteralPath "$Archive.sha256" -Destination $Checksum
    }
    else {
        if ($ReleaseBaseUrl) {
            if ($Version -eq "latest") {
                throw "centl install: a custom release base URL requires an explicit -Version"
            }
            $RequestedVersion = $Version.TrimStart("v")
            if ($RequestedVersion -notmatch '^[0-9A-Za-z.+_-]+$' -or $RequestedVersion.Contains("..")) {
                throw "centl install: the requested release version is invalid"
            }

            $BaseUri = $null
            if (-not [Uri]::TryCreate($ReleaseBaseUrl, [UriKind]::Absolute, [ref] $BaseUri)) {
                throw "centl install: the release base URL is invalid"
            }
            if ($BaseUri.Scheme -ne "https" -and $BaseUri.Scheme -ne "file") {
                throw "centl install: the release base URL must use https:// or file://"
            }
            if ($BaseUri.Query -or $BaseUri.Fragment) {
                throw "centl install: the release base URL must not contain a query or fragment"
            }

            Write-Host "Downloading CENTL $Version for windows-x86_64..."
            if ($BaseUri.Scheme -eq "file") {
                $VersionDirectory = Join-Path $BaseUri.LocalPath "v$RequestedVersion"
                $SourceArchive = Join-Path $VersionDirectory $Asset
                $SourceChecksum = "$SourceArchive.sha256"
                if (-not (Test-Path -LiteralPath $SourceArchive -PathType Leaf)) {
                    throw "centl install: release archive not found: $SourceArchive"
                }
                if (-not (Test-Path -LiteralPath $SourceChecksum -PathType Leaf)) {
                    throw "centl install: release checksum not found: $SourceChecksum"
                }
                Copy-Item -LiteralPath $SourceArchive -Destination $DownloadedArchive
                Copy-Item -LiteralPath $SourceChecksum -Destination $Checksum
            }
            else {
                $BaseUrl = $BaseUri.AbsoluteUri.TrimEnd('/') + "/v$RequestedVersion"
                Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Asset" -OutFile $DownloadedArchive
                Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Asset.sha256" -OutFile $Checksum
            }
        }
        else {
            $ReleasePath = if ($Version -eq "latest") {
                "latest/download"
            }
            elseif ($Version.StartsWith("v")) {
                "download/$Version"
            }
            else {
                "download/v$Version"
            }
            $BaseUrl = "https://github.com/$Repository/releases/$ReleasePath"
            Write-Host "Downloading CENTL $Version for windows-x86_64..."
            Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Asset" -OutFile $DownloadedArchive
            Invoke-WebRequest -UseBasicParsing -Uri "$BaseUrl/$Asset.sha256" -OutFile $Checksum
        }
    }

    $ChecksumText = (Get-Content -LiteralPath $Checksum -Raw).Trim()
    if ($ChecksumText -notmatch '^([0-9a-fA-F]{64})(?:\s|$)') {
        throw "centl install: the release checksum is malformed"
    }
    $Expected = $Matches[1].ToLowerInvariant()
    $Actual = (Get-FileHash -LiteralPath $DownloadedArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($Actual -ne $Expected) {
        throw "centl install: release checksum verification failed"
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $Zip = [IO.Compression.ZipFile]::OpenRead($DownloadedArchive)
    try {
        foreach ($Entry in $Zip.Entries) {
            $Name = $Entry.FullName.Replace('\', '/')
            if ($Name.StartsWith('/') -or $Name -notmatch '^centl(?:/|$)') {
                throw "centl install: the release archive has an unexpected layout"
            }
            if (($Name -split '/') -contains '..') {
                throw "centl install: the release archive contains an unsafe path"
            }
        }
    }
    finally {
        $Zip.Dispose()
    }

    $Extracted = Join-Path $Temporary "extracted"
    Expand-Archive -LiteralPath $DownloadedArchive -DestinationPath $Extracted
    $Package = Join-Path $Extracted "centl"
    $PackageBinary = Join-Path $Package "centl.exe"
    $PackagePhysicsBinary = Join-Path $Package "centl-physics.exe"
    $PackageSciBinary = Join-Path $Package "centl-sci.exe"
    $VersionFile = Join-Path $Package "VERSION"
    if (-not (Test-Path -LiteralPath $PackageBinary -PathType Leaf)) {
        throw "centl install: the release contains no CENTL executable"
    }
    $PhysicsAvailable = Test-Path -LiteralPath $PackagePhysicsBinary -PathType Leaf
    $SciAvailable = Test-Path -LiteralPath $PackageSciBinary -PathType Leaf
    if (-not (Test-Path -LiteralPath $VersionFile -PathType Leaf)) {
        throw "centl install: the release contains no version metadata"
    }

    $PackageVersion = (Get-Content -LiteralPath $VersionFile -TotalCount 1).Trim()
    if ($PackageVersion -notmatch '^[0-9A-Za-z.+_-]+$' -or $PackageVersion.Contains("..")) {
        throw "centl install: the release version is invalid"
    }
    if ($Version -ne "latest") {
        $Requested = $Version.TrimStart("v")
        if ($PackageVersion -ne $Requested) {
            throw "centl install: requested $Requested but the archive contains $PackageVersion"
        }
    }

    $VersionsDirectory = Join-Path $Prefix "versions"
    $Target = Join-Path $VersionsDirectory $PackageVersion
    $BinDirectory = Join-Path $Prefix "bin"
    $CommandPath = Join-Path $BinDirectory "centl.cmd"
    $PhysicsCommandPath = Join-Path $BinDirectory "centl-physics.cmd"
    $SciCommandPath = Join-Path $BinDirectory "centl-sci.cmd"
    if (Test-Path -LiteralPath $CommandPath -PathType Leaf) {
        $FirstLine = Get-Content -LiteralPath $CommandPath -TotalCount 1
        if ($FirstLine -ne "@rem CENTL launcher") {
            throw "centl install: $CommandPath already exists and is not a CENTL launcher"
        }
    }
    if ($PhysicsAvailable -and (Test-Path -LiteralPath $PhysicsCommandPath -PathType Leaf)) {
        $PhysicsFirstLine = Get-Content -LiteralPath $PhysicsCommandPath -TotalCount 1
        if ($PhysicsFirstLine -ne "@rem CENTL launcher") {
            throw "centl install: $PhysicsCommandPath already exists and is not a CENTL launcher"
        }
    }
    if ($SciAvailable -and (Test-Path -LiteralPath $SciCommandPath -PathType Leaf)) {
        $SciFirstLine = Get-Content -LiteralPath $SciCommandPath -TotalCount 1
        if ($SciFirstLine -ne "@rem CENTL launcher") {
            throw "centl install: $SciCommandPath already exists and is not a CENTL launcher"
        }
    }
    if (Test-Path -LiteralPath $Target) {
        throw "centl install: CENTL $PackageVersion is already installed at $Target"
    }

    New-Item -ItemType Directory -Path $VersionsDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $BinDirectory -Force | Out-Null
    $Staging = Join-Path $VersionsDirectory (".centl-$PackageVersion-" + [Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $Staging | Out-Null
    Copy-Item -Path (Join-Path $Package '*') -Destination $Staging -Recurse -Force

    $StagedBinary = Join-Path $Staging "centl.exe"
    $RuntimeVersion = (& $StagedBinary --version | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $RuntimeVersion -ne "centl $PackageVersion") {
        throw "centl install: executable reports '$RuntimeVersion', expected 'centl $PackageVersion'"
    }
    if ($PhysicsAvailable) {
        $StagedPhysicsBinary = Join-Path $Staging "centl-physics.exe"
        $PhysicsSmoke = (& $StagedPhysicsBinary convert 100 cm m | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $PhysicsSmoke -ne "1") {
            throw "centl install: CENTL Physics executable failed its unit-conversion smoke test: $PhysicsSmoke"
        }
    }
    if ($SciAvailable) {
        $StagedSciBinary = Join-Path $Staging "centl-sci.exe"
        $SciSmoke = (& $StagedSciBinary 'What is 0.1 plus 0.2?' | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $SciSmoke -ne "3/10") {
            throw "centl install: CENTL-SCi executable failed its exact-arithmetic smoke test: $SciSmoke"
        }
        $SciReplSmoke = (":exit`n" | & $StagedSciBinary --repl | Out-String).TrimEnd()
        if ($LASTEXITCODE -ne 0) {
            throw "centl install: CENTL-SCi REPL failed to start: $SciReplSmoke"
        }
        if ($SciReplSmoke -notmatch 'CENTL-SCi v' -or $SciReplSmoke -notmatch 'Free for science\.') {
            throw "centl install: CENTL-SCi REPL did not report the expected identity: $SciReplSmoke"
        }
    }
    Move-Item -LiteralPath $Staging -Destination $Target
    $Staging = $null

    $LauncherTemporary = "$CommandPath.new"
    $Launcher = @"
@rem CENTL launcher
@echo off
"%~dp0..\versions\$PackageVersion\centl.exe" %*
"@
    $Launcher.TrimStart() | Set-Content -LiteralPath $LauncherTemporary -Encoding ASCII
    Move-Item -LiteralPath $LauncherTemporary -Destination $CommandPath -Force

    if ($PhysicsAvailable) {
        $PhysicsLauncherTemporary = "$PhysicsCommandPath.new"
        $PhysicsLauncher = @"
@rem CENTL launcher
@echo off
"%~dp0..\versions\$PackageVersion\centl-physics.exe" %*
"@
        $PhysicsLauncher.TrimStart() | Set-Content -LiteralPath $PhysicsLauncherTemporary -Encoding ASCII
        Move-Item -LiteralPath $PhysicsLauncherTemporary -Destination $PhysicsCommandPath -Force
    }

    if ($SciAvailable) {
        $SciLauncherTemporary = "$SciCommandPath.new"
        $SciLauncher = @"
@rem CENTL launcher
@echo off
"%~dp0..\versions\$PackageVersion\centl-sci.exe" %*
"@
        $SciLauncher.TrimStart() | Set-Content -LiteralPath $SciLauncherTemporary -Encoding ASCII
        Move-Item -LiteralPath $SciLauncherTemporary -Destination $SciCommandPath -Force
    }

    $PathUpdated = $false
    if (-not $NoPath) {
        $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $Entries = @($UserPath -split ';' | Where-Object { $_ })
        if (-not ($Entries | Where-Object { $_.TrimEnd('\') -ieq $BinDirectory.TrimEnd('\') })) {
            $NewPath = (@($Entries) + $BinDirectory) -join ';'
            [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
            $PathUpdated = $true
            Write-Host "Added $BinDirectory to your user PATH."
        }
    }

    Write-Host "Installed CENTL $PackageVersion at $Target"
    Write-Host "Command: $CommandPath"
    if ($PhysicsAvailable) {
        Write-Host "Physics command: $PhysicsCommandPath"
    }
    if ($SciAvailable) {
        Write-Host "Scientific command: $SciCommandPath"
        Write-Host ""
        Write-Host "CENTL-SCi is ready."
        if ($PathUpdated) {
            Write-Host "Open a new terminal and run: centl-sci"
        }
        else {
            Write-Host "Start: centl-sci"
        }
    }
    else {
        Write-Host ""
        Write-Host "CENTL-SCi is not included in CENTL $PackageVersion."
    }
}
finally {
    if ($Staging -and (Test-Path -LiteralPath $Staging)) {
        Remove-Item -LiteralPath $Staging -Recurse -Force
    }
    if (Test-Path -LiteralPath $Temporary) {
        Remove-Item -LiteralPath $Temporary -Recurse -Force
    }
}
