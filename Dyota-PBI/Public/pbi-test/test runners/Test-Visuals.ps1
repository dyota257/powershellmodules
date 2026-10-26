# Test runner for tests\visuals.json. Called by pbi-test, which supplies the shared helpers
# (Read-Json, Print-Verbose, Console-Log, Invoke-Assertions) and the $results / $indent variables
# through dynamic scope. Returns $false if there is no visuals.json.

function Test-Visuals {
    $filepath = ".\*.CodeFiles\tests\visuals.json"

    if (!(Test-Path $filepath)) { return $false }

    $tests = Read-Json $filepath
    
    $tests |
        ForEach-Object {
            $testName = $_.name
            # identify the test that is being run
    
            Print-Verbose "`nRunning test [yellow]$($_.name)[/]"
            Console-Log "Running through all pages..."
    
            $coordinates = $_.coordinates
    
            $assertions = $_.assertions

            # report-wide test: target is report.json, no coordinates
            if ($_.scope -eq 'report') {
                $reportPath = Resolve-Path ".\*.Report\definition\report.json" -ErrorAction SilentlyContinue
                if (!$reportPath) {
                    Write-SpectreHost "[red]report.json not found[/]"
                    return
                }
                Print-Verbose "Checking [yellow]report[/]"
                Invoke-Assertions $assertions (Read-Json $reportPath) $testName 'report' $null $null $null $null $null
                return
            }
    
            $coordinates |
                ForEach-Object {
                    # one page
                    $page = $_.page.id
                    $pageName = $_.page.name
                    Print-Verbose "Checking page [yellow]$pageName...[/]"
    
                    # go through all objects
                    Console-Log "Going through all objects..."
                    
                    $objects = $_.objects
    
                    $objects | 
                        ForEach-Object {
    
                            $visualid = $_.id
                            Console-Log "Going through all objects..."
                            $path = ".\*.Report\definition\pages\$page\visuals\$visualid\visual.json"
                            
                            $visual = Read-Json $path
                            
                            # visual type and name propeerties based on a tableEx
                            $objectType = $visual.visual.visualType
                            $objectName = $visual.visual.visualContainerObjects.title[0].properties.text.expr.Literal.Value
    
                            Print-Verbose "$indent Checking $objectType [yellow]$objectName[/]"
                            
                            Invoke-Assertions $assertions $visual $testName 'visual' $page $pageName $visualid $objectName $objectType
                        }
                }
        }
    return $true
}
