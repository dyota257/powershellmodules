function Export-DAX ($dest, $model) {
    Write-Host -ForegroundColor Cyan "Ripping DAX... " -NoNewline

    if ((Test-Path $dest) -eq $false) { New-Item -ItemType Directory $dest | Out-Null }

    # measures
    $model.model.tables |
        Where-Object {
            $null -ne $_.measures
        } |
        ForEach-Object {
            $tableName = $_.name
            $path = "$dest\$tableName\Measures"
            $pathKpis = "$dest\$tableName\KPIs"

            $_.measures |
                ForEach-Object {
                    if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }

                    # illegal characters in filenames. the last two are invisible characters that Claude put in
                    $name = $_.name -replace '[<>:"/\\|?*\x00-\x1F]', ''
                    

                    # append the name of the measure
                    $expression = -join "$($_.name) = ", $($_.expression)

                    Set-Content -Path "$path\$name.dax" -Value $expression

                    if ($null -ne $_.kpi) {
                        if ((Test-Path "$pathKpis\$name") -eq $false) { New-Item -ItemType Directory "$pathKpis\$name" | Out-Null }

                        $kpi = $_.kpi

                        if ($null -ne $kpi.statusExpression) {
                            $status = "// $($kpi.statusDescription)`n$($kpi.statusExpression -join "`n")"
                            Set-Content -Path "$pathKpis\$name\$name.Status.dax" -Value $status
                        }
                        if ($null -ne $kpi.targetExpression) {
                            $target = "// $($kpi.targetDescription)`n$($kpi.targetExpression -join "`n")"
                            Set-Content -Path "$pathKpis\$name\$name.Target.dax" -Value $target
                        }
                        if ($null -ne $kpi.trendExpression) {
                            $trend = "// $($kpi.trendDescription)`n$($kpi.trendExpression -join "`n")"
                            Set-Content -Path "$pathKpis\$name\$name.Trend.dax" -Value $trend
                        }
                    }


                }

        }

    # calculated columns
    $model.model.tables |
        Where-Object {
            $_.annotations.name -eq 'PBI_ResultType'
        } |
        ForEach-Object {
            $tableName = $_.name
            $path = "$dest\$tableName\Calculated Columns"

            # $tableName
            $_.columns |
                Where-Object { $_.type -eq 'calculated' } |
                ForEach-Object {
                    if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }

                    # illegal characters in filenames
                    $name = $_.name -replace '[<>:"/\\|?*\x00-\x1F]', ''

                    # append the name of the measure
                    $expression = -join "$($_.name) = ", $($_.expression)

                    Set-Content -Path "$path\$name.dax" -Value $expression
                }
        }

    # calculated tables
    $model.model.tables.partitions |
        Where-Object {
            ($_.source.type -eq 'calculated') -and
            -not ($_.name -like "LocalDateTable*") -and
            -not ($_.name -like "DateTableTemplate*")
        } |
        ForEach-Object {
            $tableName = $_.name
            $path = "$dest\Calculated Tables"

            if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }

            $expression = $_.source.expression
            Set-Content -Path "$path\$tableName.dax" -Value $expression

        }

    # calculation groups
    $model.model.tables |
        Where-Object {
            $null -ne $_.calculationGroup
        } |
        ForEach-Object {
            $tableName = $_.name
            $path = "$dest\$tableName\Calculation Groups"
            if ((Test-Path $path) -eq $false) { New-Item -ItemType Directory $path | Out-Null }

            $_.calculationGroup.calculationItems |
                % {
                    $calcName = $_.name
                    $expression = $_.expression
                    Set-Content -Path "$path\$calcName.dax" -Value $expression
                }
        }

    Write-Host -ForegroundColor Cyan "Code ripped and stored in " -NoNewLine
    Write-Host -ForegroundColor Green "$dest"

}
