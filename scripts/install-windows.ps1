# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Windows 11 Automated Installer

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if (-not $RootDir) { $RootDir = (Get-Location).Path }
Set-Location $RootDir

Write-Host "=== CentL26 Windows 11 Setup ===" -ForegroundColor Cyan

# 1. Check Rust toolchain
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Rust toolchain not found. Installing via winget..." -ForegroundColor Yellow
    winget install Rustlang.Rustup -e --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# 2. Compile release binary
Write-Host "Compiling CentL26..." -ForegroundColor Cyan
cargo build --release --bin centl26

# 3. Create Windows start menu and desktop shortcut
$LocalBin = Join-Path $env:LOCALAPPDATA "Programs\CentL26"
New-Item -ItemType Directory -Force -Path $LocalBin | Out-Null

Copy-Item "target\release\centl26.exe" (Join-Path $LocalBin "centl26.exe") -Force
Copy-Item "desktop\centl26\windows\CentL26.ico" (Join-Path $LocalBin "CentL26.ico") -Force

# Create Desktop Shortcut
$WScriptShell = New-Object -ComObject WScript.Shell
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")
$Shortcut = $WScriptShell.CreateShortcut((Join-Path $DesktopPath "CentL26.lnk"))
$Shortcut.TargetPath = (Join-Path $LocalBin "centl26.exe")
$Shortcut.IconLocation = (Join-Path $LocalBin "CentL26.ico")
$Shortcut.Description = "CentL26 Scientific Computing Workbench"
$Shortcut.Save()

# Create Start Menu Shortcut
$StartMenuPath = [System.Environment]::GetFolderPath("StartMenu")
$StartShortcut = $WScriptShell.CreateShortcut((Join-Path $StartMenuPath "Programs\CentL26.lnk"))
$StartShortcut.TargetPath = (Join-Path $LocalBin "centl26.exe")
$StartShortcut.IconLocation = (Join-Path $LocalBin "CentL26.ico")
$StartShortcut.Description = "CentL26 Scientific Computing Workbench"
$StartShortcut.Save()

Write-Host "CentL26 installed successfully on Windows 11!" -ForegroundColor Green
Write-Host "Shortcut created on your Desktop and Start Menu." -ForegroundColor Green
