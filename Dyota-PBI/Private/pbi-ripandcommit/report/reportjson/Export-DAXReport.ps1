function Export-DAXReport($dest, $report) {
    # this is if the report is a child of a semantic model and has measures of its own

    $config = $report.config | ConvertFrom-Json

    $config |
        ForEach-Object {
            $entities = $_.modelExtensions.entities
            if ($entities.Count -gt 0) {
                $entities |
                    ForEach-Object {
                        $tableName = $_.name

                        $dest = "$dest\$tableName\Measures"
                        if ((Test-Path $dest) -eq $false) { New-Item -ItemType Directory $dest | Out-Null }

                        $_.measures |
                            ForEach-Object {
                                $name = ($_.name) -replace [RegEx]::Escape('/'), '' -replace [RegEx]::Escape(':'), ''
                                $expression = -join "$($_.name) = ", $($_.expression)
                                Set-Content -Path "$dest\$name.dax" -Value $expression
                            }

                        Write-Host -ForegroundColor Cyan "Code ripped and stored in " -NoNewline
                        Write-Host -ForegroundColor Green "$dest"
                    }
            }
        }
}
