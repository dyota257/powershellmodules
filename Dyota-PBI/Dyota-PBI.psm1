# Generated with Claude Code (claude-sonnet-4-5-20250929) on 2025-10-23

using namespace System.Collections.Generic
using namespace System.Text

# Load Analysis Services assemblies once — individual private files must not call Add-Type for these
$_asBasePath = "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\microsoft.analysisservices.19.107.2\lib\net8.0"
# FabricPS-PBIP loads its bundled TOM assemblies when publishing. Share that
# version: PowerShell cannot load both versions into the same assembly context.
$_fabricModule = Get-Module -ListAvailable FabricPS-PBIP | Select-Object -First 1
# The Fabric bundle (19.84.x) predates DAX user-defined functions (TMDL 'function'),
# so it's only a fallback when the newer NuGet package is missing.
if ($_fabricModule -and -not [System.IO.Directory]::Exists($_asBasePath)) {
    $_fabricAssemblyPath = Get-ChildItem -Path (Join-Path $_fabricModule.ModuleBase '.nuget\Microsoft.AnalysisServices.NetCore.retail.amd64.*\lib\netcoreapp3.0') -Directory -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1
    if ($_fabricAssemblyPath) {
        $_asBasePath = $_fabricAssemblyPath.FullName
    }
}
# Runtime.* must be preloaded too: otherwise they load lazily, and if SqlServer/FabricPS-PBIP
# gets an older Runtime.Core in first, Tabular fails with "manifest definition does not match".
@(
    'Microsoft.AnalysisServices.Runtime.Core.dll'
    'Microsoft.AnalysisServices.Runtime.Windows.dll'
    'Microsoft.AnalysisServices.dll'
    'Microsoft.AnalysisServices.Core.dll'
    'Microsoft.AnalysisServices.Tabular.dll'
    'Microsoft.AnalysisServices.Tabular.Json.dll'
) | ForEach-Object {
    [string]$_dllPath = [System.IO.Path]::Combine($_asBasePath, $_)
    $_assemblyName = [System.IO.Path]::GetFileNameWithoutExtension($_)
    $_loadedAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GetName().Name -eq $_assemblyName } | Select-Object -First 1
    if (!$_loadedAssembly -and [System.IO.File]::Exists($_dllPath)) {
        Add-Type -Path $_dllPath -ErrorAction SilentlyContinue
    }
}

# FabricPS-PBIP unconditionally Add-Types its bundled TOM (19.84), which throws once the
# assemblies above are loaded (.NET can't hold two versions). Import it now, with Add-Type
# shadowed to skip already-loaded assemblies, so later Import-Module calls are no-ops.
if ($_fabricModule -and !(Get-Module FabricPS-PBIP)) {
    function global:Add-Type {
        [CmdletBinding()]
        param([string[]] $Path)
        foreach ($p in $Path) {
            $name = [System.IO.Path]::GetFileNameWithoutExtension($p)
            if (![AppDomain]::CurrentDomain.GetAssemblies().Where({ $_.GetName().Name -eq $name }, 'First')) {
                Microsoft.PowerShell.Utility\Add-Type -Path $p
            }
        }
    }
    try {
        Import-Module FabricPS-PBIP -Global -ErrorAction SilentlyContinue 6>$null
    }
    finally {
        Remove-Item -LiteralPath 'Function:\Add-Type' -Force -ErrorAction SilentlyContinue
    }
}

# Dot source all private functions
$PrivateFunctions = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Recurse -ErrorAction SilentlyContinue)

foreach ($import in $PrivateFunctions) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import private function $($import.FullName): $_"
    }
}

# Dot source all public functions
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Recurse -ErrorAction SilentlyContinue)

foreach ($import in $PublicFunctions) {
    try {
        . $import.FullName

        # Write-Host "Imported $($import.FullName)"
    }
    catch {
        Write-Error -Message "Failed to import public function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias *
