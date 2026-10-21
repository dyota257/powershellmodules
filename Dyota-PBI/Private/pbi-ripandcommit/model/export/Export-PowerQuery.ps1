using namespace System.Text.RegularExpressions

function Export-PowerQuery ([string] $dest, [PSCustomObject] $model) {
    # given a the contents of a model.bim file ($model, parsed from in JSON), rip out all of the Power Query code and save it in $dest
    Write-Host -ForegroundColor Cyan "Ripping PQ... " -NoNewline

    if ((Test-Path $dest) -eq $false) { New-Item -ItemType Directory $dest | Out-Null }

    # these are PQ scripts that are loaded to the data model as tables
    $model.model.tables |
        Where-Object {
            $_.annotations.name -eq 'PBI_ResultType'
        } |
        ForEach-Object {
            # $queryGroup = $_.partitions.queryGroup    # this is for model.bim
            $queryGroup = $_.partitions.queryGroup.name # in Tabular.Database, there is a "name" property
            $path = "$dest\$queryGroup"

            if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }

            $name = ($_.name) -replace [RegEx]::Escape('/'), '' -replace [RegEx]::Escape(':'), '' -replace [RegEx]::Escape('>'), ''

            Set-Content -Path "$path\$($name).pq" -Value $_.partitions.source.expression
        }

    # these are PQ scripts that are _not_ loaded to the data model (tables or otherwise)
    $model.model.expressions |
        ForEach-Object {
            # $queryGroup = $_.queryGroup    # this is for model.bim
            $queryGroup = $_.queryGroup.name # in Tabular.Database, there is a "name" property
            $path = "$dest\$queryGroup"
            if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }
            $name = ($_.name) -replace [RegEx]::Escape('/'), '' -replace [RegEx]::Escape(':'), '' -replace [RegEx]::Escape('>'), ''

            Set-Content -Path "$path\$($name).pq" -Value $_.expression
        }

    Write-Host -ForegroundColor Cyan "Code ripped and stored in " -NoNewline
    Write-Host -ForegroundColor Green "$dest"

}
