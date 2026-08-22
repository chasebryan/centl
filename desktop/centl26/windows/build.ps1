# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Windows 11 Build & Package Script (CentL26.10 Universal Release)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (-not $RootDir) { $RootDir = (Get-Location).Path }
Set-Location $RootDir

Write-Host "=== Building CentL26 for Windows 11 (x86_64) ===" -ForegroundColor Cyan

# 1. Compile release binary
Write-Host "Compiling release binary..." -ForegroundColor Gray
cargo build --release --bin centl26

$BuildDir = Join-Path $RootDir "build\centl26"
$DistDir = Join-Path $BuildDir "windows"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# 2. Copy binary, icon, and batch launcher
Copy-Item "target\release\centl26.exe" (Join-Path $DistDir "centl26.exe") -Force
Copy-Item "desktop\centl26\windows\CentL26.ico" (Join-Path $DistDir "CentL26.ico") -Force
Copy-Item "desktop\centl26\windows\CentL26.bat" (Join-Path $DistDir "CentL26.bat") -Force

# 3. Create README and license notices
$ReadmeContent = @"
=====================================================
CentL26 Scientific Computing Workbench
Version: 26.10.0 (Windows 11 x86_64)
Free Computation Foundation · Apache-2.0
=====================================================

To run CentL26:
  1. Double click CentL26.bat or centl26.exe
  2. The application opens in your default browser at http://127.0.0.1:2626
  3. Continuous exact calculations, Jupyter Notebook compatibility,
     STEM dynamic visualizer, and academic search are ready.

Documentation & Papers: https://freecomputation.org
Source Code: https://github.com/chasebryan/centl
"@
Set-Content -Path (Join-Path $DistDir "README.txt") -Value $ReadmeContent -Encoding UTF8

if (Test-Path "LICENSE") {
    Copy-Item "LICENSE" (Join-Path $DistDir "LICENSE.txt") -Force
}

# 4. Generate Build Manifest
$Manifest = @{
    "name" = "CentL26"
    "version" = "26.10.0"
    "platform" = "windows-x86_64"
    "target" = "x86_64-pc-windows-msvc"
    "timestamp" = (Get-Date -Format "o")
    "binaries" = @("centl26.exe")
    "schema" = "centl26.build-manifest/1"
} | ConvertTo-Json -Depth 4
Set-Content -Path (Join-Path $DistDir "BUILD_MANIFEST.json") -Value $Manifest -Encoding UTF8

# 5. Create Standalone Distribution Zip Archive
$ZipPath = Join-Path $BuildDir "CentL26-Windows-x86_64.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

Write-Host "Creating distribution zip archive..." -ForegroundColor Gray
Compress-Archive -Path "$DistDir\*" -DestinationPath $ZipPath -Force

# 6. Compute SHA-256 Checksum
if (Test-Path $ZipPath) {
    $Hash = (Get-FileHash -Path $ZipPath -Algorithm SHA256).Hash
    Set-Content -Path "$ZipPath.sha256" -Value "$Hash  CentL26-Windows-x86_64.zip" -Encoding UTF8
    Write-Host "SHA-256: $Hash" -ForegroundColor Yellow
}

Write-Host "=== CentL26 Windows 11 Build Complete ===" -ForegroundColor Green
Write-Host "  Staging directory: $DistDir" -ForegroundColor Gray
Write-Host "  Release archive:   $ZipPath" -ForegroundColor Green
