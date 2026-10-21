<#
2025 Microsoft introduced a new way of organising the report definition in PBIP
need o be able to tell the difference between the two formats
#>

function Get-PBIPReportFormat ([string] $path) {

    # If no path provided, use current directory
    if ($null -eq $path -or '' -eq $path) {
        $path = (Get-Location).Path
    }

    $projectName = Split-Path $path -Leaf
    $reportFolder = "$path\$projectName.Report"

    # Check if Report folder exists
    if (!(Test-Path $reportFolder)) {
        Write-Error "$reportFolder doesn't exist"
        break; 
    }

    # This is the main indicator for the new PBIR report format
    $hasDefinitionFolder = Test-Path "$reportFolder\definition"

    # This is the main indicator for the old report.json format
    $hasReportJsonDirect = Test-Path "$reportFolder\report.json"

    if ($hasDefinitionFolder) {
        return 1 # "PBIR"  # New format
    }
    elseif ($hasReportJsonDirect) {
        return 0 # "PBIP"  # Old format
    }
    else {
        return 999 # "Unknown"
    }
}