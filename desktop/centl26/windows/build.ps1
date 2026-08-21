# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Windows 11 Build & Package Script

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
if (-not $RootDir) { $RootDir = (Get-Location).Path }
Set-Location $RootDir

Write-Host "=== Building CentL26 for Windows 11 ===" -ForegroundColor Cyan

# 1. Compile release binary
cargo build --release --bin centl26

$DistDir = Join-Path $RootDir "build\centl26\windows"
New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

# 2. Copy binary and icon
Copy-Item "target\release\centl26.exe" (Join-Path $DistDir "centl26.exe") -Force
Copy-Item "desktop\centl26\windows\CentL26.ico" (Join-Path $DistDir "CentL26.ico") -Force
Copy-Item "desktop\centl26\windows\CentL26.bat" (Join-Path $DistDir "CentL26.bat") -Force

Write-Host "CentL26 Windows build complete: $DistDir\centl26.exe" -ForegroundColor Green
