@echo off
setlocal
cd /d "%~dp0"

if exist "centl26.exe" (
    "%~dp0centl26.exe" %*
    exit /b %ERRORLEVEL%
)

if exist "..\..\..\target\release\centl26.exe" (
    "%~dp0..\..\..\target\release\centl26.exe" %*
    exit /b %ERRORLEVEL%
)

echo Building CentL26...
cargo run --release --bin centl26 -- %*
