# Claude Sonnet 4.5 (claude-sonnet-4-5-20250929) - 2025-11-24

# using namespace Microsoft.AnalysisServices

# Install the NuGet package first:
# Install-Package Microsoft.AnalysisServices.NetCore.retail.amd64

# Add the assembly
# Add-Type -Path "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\microsoft.analysisservices.19.107.2\lib\net8.0\Microsoft.AnalysisServices.Core.dll"
# Add-Type -Path "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\microsoft.analysisservices.19.107.2\lib\net8.0\Microsoft.AnalysisServices.Tabular.dll"
# Add-Type -Path "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\microsoft.analysisservices.19.107.2\lib\net8.0\Microsoft.AnalysisServices.Tabular.Json.dll"

# $modelPath = "C:\Users\iCatalyst\Documents\temp\2025-11-24\BG&E D365 Reporting\BG&E D365 Reporting.SemanticModel\definition"

function pbi-tmdlDsrl ($modelPath) {
    $model = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder($modelPath)
    return $model
}