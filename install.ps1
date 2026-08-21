# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Root Windows Installer

$PSScriptRoot_Local = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PSScriptRoot_Local
& ".\scripts\install-windows.ps1"
