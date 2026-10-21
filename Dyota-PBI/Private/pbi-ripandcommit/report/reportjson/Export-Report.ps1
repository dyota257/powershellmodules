function Export-Report ($dest, $report) {

    # each "section" is a page in the Power BI report
    $sections = $report.sections |
        ? {
            !$_.displayName.Contains("❓")
        }

    Write-Host -ForegroundColor Cyan "I see $($sections.Count) pages... " -NoNewline
    Write-Host -ForegroundColor Cyan "Ripping pages... " -NoNewline

    $sections |
        % {
            $pageName = $_.displayName.Trim() -replace [RegEx]::Escape('/'), '' -replace [RegEx]::Escape(':'), ''

            $path = "$dest\$pageName"
            if (!(Test-Path "$path")) { New-Item -ItemType Directory $path | Out-Null }

            # a 'container' is a visual on the page
            $visuals = $_.visualContainers

            $visuals |
                % {
                    $visualConfig = $_.config | ConvertFrom-Json

                    $name = $visualConfig.name

                    $type = $visualConfig.singleVisual.visualType

                    if ($null -ne $type) {
                        # depth needs to be set to a big number (20) because lots of nested properties
                        Set-Content -Path "$path\$type $name config.json" -Value ($visualConfig | ConvertTo-Json -Depth 20)
                    }
                }
        }
    Write-Host -ForegroundColor Cyan "All objects from all pages ripped"
}
