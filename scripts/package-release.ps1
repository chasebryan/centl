[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $Version,

    [Parameter(Position = 1)]
    [string] $OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) "dist"),

    [string] $Binary = (Join-Path (Split-Path -Parent $PSScriptRoot) "_build\default\src\main.exe")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$Version = $Version.TrimStart("v")
if ($Version -notmatch '^[0-9A-Za-z.+_-]+$' -or $Version.Contains("..")) {
    throw "centl package: invalid version: $Version"
}
if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
    throw "centl package: Windows release packaging currently supports x86_64 only"
}
if (-not (Test-Path -LiteralPath $Binary -PathType Leaf)) {
    throw "centl package: build CENTL before packaging: $Binary"
}

$ReportedVersion = (& $Binary --version | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $ReportedVersion -ne "centl $Version") {
    throw "centl package: binary reports '$ReportedVersion', expected 'centl $Version'"
}

function Copy-License {
    param([string] $Destination, [string[]] $Candidates)
    foreach ($Candidate in $Candidates) {
        if ($Candidate -and (Test-Path -LiteralPath $Candidate -PathType Leaf)) {
            Copy-Item -LiteralPath $Candidate -Destination $Destination
            return
        }
    }
    throw "centl package: could not locate $Destination"
}

function Get-DllNames {
    param([string] $Object)
    $Output = & $script:Objdump.Source -p $Object
    if ($LASTEXITCODE -ne 0) {
        throw "centl package: objdump failed for $Object"
    }
    foreach ($Line in $Output) {
        if ($Line -match '^\s*DLL Name:\s*(.+?)\s*$') {
            $Matches[1]
        }
    }
}

$Objdump = Get-Command objdump.exe -ErrorAction SilentlyContinue
if (-not $Objdump) {
    $Objdump = Get-Command objdump -ErrorAction SilentlyContinue
}
if (-not $Objdump) {
    throw "centl package: objdump is required to collect Windows runtime libraries"
}

$SearchDirectories = [System.Collections.Generic.List[string]]::new()
$BinaryDirectory = Split-Path -Parent (Resolve-Path -LiteralPath $Binary)
$SearchDirectories.Add($BinaryDirectory)
$NativeStubDirectory = Join-Path $BinaryDirectory "native"
if (Test-Path -LiteralPath $NativeStubDirectory -PathType Container) {
    $SearchDirectories.Add((Resolve-Path -LiteralPath $NativeStubDirectory).Path)
}
if ($env:CENTL_RUNTIME_PATHS) {
    foreach ($Directory in $env:CENTL_RUNTIME_PATHS.Split([IO.Path]::PathSeparator)) {
        if ($Directory -and (Test-Path -LiteralPath $Directory -PathType Container)) {
            $SearchDirectories.Add((Resolve-Path -LiteralPath $Directory).Path)
        }
    }
}

$Temporary = Join-Path ([IO.Path]::GetTempPath()) ("centl-package-" + [Guid]::NewGuid().ToString("N"))
$Package = Join-Path $Temporary "centl"
$Licenses = Join-Path $Package "licenses"
New-Item -ItemType Directory -Path $Licenses -Force | Out-Null

try {
    $PackagedBinary = Join-Path $Package "centl.exe"
    Copy-Item -LiteralPath $Binary -Destination $PackagedBinary

    $Pending = [System.Collections.Generic.Queue[string]]::new()
    $Pending.Enqueue($PackagedBinary)
    $Visited = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $SystemDirectory = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)

    while ($Pending.Count -gt 0) {
        $Object = $Pending.Dequeue()
        foreach ($Dll in (Get-DllNames $Object)) {
            if (-not $Visited.Add($Dll)) { continue }
            if ($Dll -match '^(api-ms-win-|ext-ms-win-)') { continue }

            $Resolved = $null
            foreach ($Directory in $SearchDirectories) {
                $Candidate = Join-Path $Directory $Dll
                if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
                    $Resolved = (Resolve-Path -LiteralPath $Candidate).Path
                    break
                }
            }
            if (-not $Resolved) {
                $SystemCandidate = Join-Path $SystemDirectory $Dll
                if (Test-Path -LiteralPath $SystemCandidate -PathType Leaf) { continue }
                throw "centl package: could not resolve runtime library $Dll required by $Object"
            }

            $Destination = Join-Path $Package $Dll
            if (-not (Test-Path -LiteralPath $Destination)) {
                Copy-Item -LiteralPath $Resolved -Destination $Destination
                $Pending.Enqueue($Destination)
            }
        }
    }

    Copy-Item -LiteralPath (Join-Path $ProjectRoot "LICENSE") `
        -Destination (Join-Path $Licenses "CENTL-AGPL-3.0-or-later")
    Copy-License (Join-Path $Licenses "FLINT") @($env:CENTL_FLINT_LICENSE)
    Copy-License (Join-Path $Licenses "GMP") @($env:CENTL_GMP_LICENSE)
    Copy-License (Join-Path $Licenses "MPFR") @($env:CENTL_MPFR_LICENSE)
    Copy-License (Join-Path $Licenses "FSTAR") @($env:CENTL_FSTAR_LICENSE)
    Copy-License (Join-Path $Licenses "OCAML") @($env:CENTL_OCAML_LICENSE)
    Copy-License (Join-Path $Licenses "ZARITH") @($env:CENTL_ZARITH_LICENSE)
    Copy-License (Join-Path $Licenses "YOJSON") @($env:CENTL_YOJSON_LICENSE)

    $ThirdPartyNotices = @"
CENTL includes or links components from F*, OCaml, Zarith, Yojson, FLINT, GMP,
and MPFR. Their complete license notices are shipped in the licenses directory.
Build-time-only test and compiler dependencies are not included in this archive.
"@
    $ThirdPartyNotices.TrimStart() | Set-Content `
        -LiteralPath (Join-Path $Package "THIRD-PARTY-NOTICES") -Encoding UTF8
    $Version | Set-Content -LiteralPath (Join-Path $Package "VERSION") -Encoding ASCII
    $Readme = @"
CENTL $Version for Windows x86_64

Run centl.exe. Required native libraries are included beside the executable.
License notices are in the licenses directory.
"@
    $Readme.TrimStart() | Set-Content -LiteralPath (Join-Path $Package "README.txt") -Encoding UTF8

    $Smoke = (& $PackagedBinary '0.1 + 0.2' | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $Smoke -ne "3/10") {
        throw "centl package: packaged executable failed its smoke test: $Smoke"
    }

    $EpochText = if ($env:SOURCE_DATE_EPOCH) { $env:SOURCE_DATE_EPOCH } else { "315532800" }
    $Epoch = 0L
    if (-not [Int64]::TryParse($EpochText, [ref] $Epoch) -or $Epoch -lt 0) {
        throw "centl package: SOURCE_DATE_EPOCH must be a non-negative integer"
    }
    $Timestamp = [DateTimeOffset]::FromUnixTimeSeconds($Epoch).UtcDateTime
    Get-ChildItem -LiteralPath $Package -Recurse -Force | ForEach-Object {
        $_.LastWriteTimeUtc = $Timestamp
    }
    (Get-Item -LiteralPath $Package).LastWriteTimeUtc = $Timestamp

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $Asset = "centl-windows-x86_64.zip"
    $Archive = Join-Path $OutputDirectory $Asset
    Compress-Archive -LiteralPath $Package -DestinationPath $Archive -CompressionLevel Optimal -Force
    $Digest = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
    "$Digest  $Asset" | Set-Content -LiteralPath "$Archive.sha256" -Encoding ASCII
    Write-Output $Archive
}
finally {
    if (Test-Path -LiteralPath $Temporary) {
        Remove-Item -LiteralPath $Temporary -Recurse -Force
    }
}
