@echo off
setlocal
cd /d "%~dp0"

if exist "centl26.exe" (
    start "" "centl26.exe"
    exit /b 0
)

if exist "..\..\..\target\release\centl26.exe" (
    start "" "..\..\..\target\release\centl26.exe"
    exit /b 0
)

echo Building CentL26...
cargo run --release --bin centl26
