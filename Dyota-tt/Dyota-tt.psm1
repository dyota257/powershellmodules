# Generated with Claude Code (claude-sonnet-4-5-20250929) on 2025-10-23

using namespace System.Collections.Generic
using namespace System.Text

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

        Write-Host "Imported $($import.FullName)"
    }
    catch {
        Write-Error -Message "Failed to import public function $($import.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
