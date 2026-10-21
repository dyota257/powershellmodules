# Generated with Claude Code (claude-sonnet-4-5-20250929) on 2025-10-23

using namespace System.Collections.Generic
using namespace System.Text

# Load Analysis Services assemblies once — individual private files must not call Add-Type for these
$_asBasePath = "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\microsoft.analysisservices.19.107.2\lib\net8.0"
@(
    'Microsoft.AnalysisServices.dll'
    'Microsoft.AnalysisServices.Core.dll'
    'Microsoft.AnalysisServices.Tabular.dll'
    'Microsoft.AnalysisServices.Tabular.Json.dll'
) | ForEach-Object {
    [string]$_dllPath = [System.IO.Path]::Combine($_asBasePath, $_)
    if ([System.IO.File]::Exists($_dllPath)) {
        Add-Type -Path $_dllPath -ErrorAction SilentlyContinue
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
Export-ModuleMember -Function $PublicFunctions.BaseName
