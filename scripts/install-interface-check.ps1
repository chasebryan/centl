Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $Root "install.ps1"
$Version = "0.0.0-install-test"
$Work = Join-Path ([IO.Path]::GetTempPath()) ("centl-install-check-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $Work | Out-Null

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) {
        throw $Message
    }
}

try {
    # Parse the installer before constructing the synthetic package.
    $ParseErrors = $null
    [void] [Management.Automation.Language.Parser]::ParseFile(
        $Installer,
        [ref] $null,
        [ref] $ParseErrors
    )
    if ($ParseErrors.Count -ne 0) {
        throw "PowerShell installer parse failure: $($ParseErrors | Out-String)"
    }

    $PayloadRoot = Join-Path $Work "payload"
    $Package = Join-Path $PayloadRoot "centl"
    New-Item -ItemType Directory -Path $Package -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $Package "VERSION") -Value $Version -Encoding ASCII

    $Source = @"
using System;
using System.IO;

public static class Program {
    public static int Main(string[] args) {
        string invoked = Path.GetFileNameWithoutExtension(Environment.GetCommandLineArgs()[0]).ToLowerInvariant();
        if (invoked == "centl") {
            if (args.Length == 1 && args[0] == "--version") {
                Console.WriteLine("centl 0.0.0-install-test");
                return 0;
            }
            Console.Error.WriteLine("fake centl: unsupported test input");
            return 2;
        }
        if (invoked == "centl-physics") {
            if (args.Length == 4 && args[0] == "convert" && args[1] == "100" && args[2] == "cm" && args[3] == "m") {
                Console.WriteLine("1");
                return 0;
            }
            Console.Error.WriteLine("fake centl-physics: unsupported test input");
            return 2;
        }
        if (invoked == "centl-sci") {
            if (args.Length == 1 && args[0] == "What is 0.1 plus 0.2?") {
                Console.WriteLine("3/10");
                return 0;
            }
            if (args.Length == 1 && args[0] == "--repl") {
                Console.WriteLine("CENTL-SCi v0.0.1-Camelus");
                Console.WriteLine("Free for science.");
                Console.WriteLine();
                Console.Write("> ");
                string command = Console.ReadLine();
                return command == ":exit" ? 0 : 2;
            }
            Console.Error.WriteLine("fake centl-sci: unsupported test input");
            return 2;
        }
        Console.Error.WriteLine("unexpected executable identity: " + invoked);
        return 2;
    }
}
"@

    $TemplateExe = Join-Path $Work "template.exe"
    Add-Type -TypeDefinition $Source -OutputAssembly $TemplateExe -OutputType ConsoleApplication
    foreach ($Name in @("centl.exe", "centl-physics.exe", "centl-sci.exe")) {
        Copy-Item -LiteralPath $TemplateExe -Destination (Join-Path $Package $Name)
    }

    $Archive = Join-Path $Work "centl-windows-x86_64.zip"
    Compress-Archive -Path $Package -DestinationPath $Archive
    $Digest = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath "$Archive.sha256" -Value "$Digest  $([IO.Path]::GetFileName($Archive))" -Encoding ASCII

    # Exercise the FCF/static release contract through file:// without contacting
    # GitHub or another network service.
    $StaticRoot = Join-Path $Work "static-releases"
    $StaticVersion = Join-Path $StaticRoot "v$Version"
    New-Item -ItemType Directory -Path $StaticVersion -Force | Out-Null
    Copy-Item -LiteralPath $Archive -Destination (Join-Path $StaticVersion ([IO.Path]::GetFileName($Archive)))
    Copy-Item -LiteralPath "$Archive.sha256" -Destination (Join-Path $StaticVersion "$([IO.Path]::GetFileName($Archive)).sha256")
    $StaticUri = ([Uri] ([IO.Path]::GetFullPath($StaticRoot) + [IO.Path]::DirectorySeparatorChar)).AbsoluteUri.TrimEnd('/')

    $Prefix = Join-Path $Work "installed"
    & $Installer -Version $Version -ReleaseBaseUrl $StaticUri -Prefix $Prefix -NoPath
    Assert-True ($LASTEXITCODE -eq 0) "static release-root installer returned nonzero"
    foreach ($Command in @("centl.cmd", "centl-physics.cmd", "centl-sci.cmd")) {
        Assert-True (Test-Path -LiteralPath (Join-Path (Join-Path $Prefix "bin") $Command) -PathType Leaf) "installer did not activate $Command"
    }

    $SciOutput = (& (Join-Path (Join-Path $Prefix "bin") "centl-sci.cmd") 'What is 0.1 plus 0.2?' | Out-String).Trim()
    Assert-True ($SciOutput -eq "3/10") "installed CENTL-SCi returned '$SciOutput'"

    $LatestRejected = $false
    try {
        & $Installer -ReleaseBaseUrl $StaticUri -Prefix (Join-Path $Work "latest") -NoPath
    }
    catch {
        $LatestRejected = $_.Exception.Message -like '*requires an explicit -Version*'
    }
    Assert-True $LatestRejected "custom release root unexpectedly accepted implicit latest"

    $InsecureRejected = $false
    try {
        & $Installer -Version $Version -ReleaseBaseUrl "http://example.invalid/releases" -Prefix (Join-Path $Work "insecure") -NoPath
    }
    catch {
        $InsecureRejected = $_.Exception.Message -like '*must use https:// or file://*'
    }
    Assert-True $InsecureRejected "installer unexpectedly accepted an insecure release base URL"

    $ConflictRejected = $false
    try {
        & $Installer -Version $Version -ReleaseBaseUrl $StaticUri -Archive $Archive -Prefix (Join-Path $Work "conflict") -NoPath
    }
    catch {
        $ConflictRejected = $_.Exception.Message -like '*mutually exclusive*'
    }
    Assert-True $ConflictRejected "installer unexpectedly accepted both Archive and ReleaseBaseUrl"

    Write-Host "CENTL Windows installer interface check: PASS"
}
finally {
    if (Test-Path -LiteralPath $Work) {
        Remove-Item -LiteralPath $Work -Recurse -Force
    }
}
