using namespace System.Collections.Generic

function pbi-test (
    [switch] $PassThru,
    [switch] $verbose
){

    function Read-Json ($path) {
        Get-Content $path | ConvertFrom-Json -Depth 20
    }
    
    function Console-Log ($text) {
        # comment out this command to deactivate all of the "console-logs"
        # Write-Host -ForegroundColor DarkGray ">> $text"
    }

    function Print-Verbose ($text) {
        # only print to console if -verbose is on
        if ($verbose) { Write-SpectreHost $text }
    }
    
    function Invoke-Assertions ($assertions, $target, $testName, $scope, $page, $pageName, $visualid, $objectName, $objectType) {
        # $visual is kept as an alias of $target so older assertions still work
        $visual = $target

        $assertions |
            ForEach-Object {
                $code = $_.code -join ""
                $sb = [scriptblock]::Create($code)
                $result = & $sb
                $description = $_.description.replace('[', '[[').replace(']', ']]') # escape square brackets so that write-host doesn't mistake them for directives

                if ($result) {
                    Print-Verbose "$indent$indent [green]✅[/] $description"
                } else {
                    # always print failures
                    Write-SpectreHost "$indent$indent [red]❌[/] $description"
                }

                $results.Add(
                    [PSCustomObject]@{
                        TestName    = $testName
                        Scope       = $scope
                        PageId      = $page
                        PageName    = $pageName
                        VisualId    = $visualid
                        VisualName  = $objectName
                        VisualType  = $objectType
                        Description = $_.description
                        Passed      = [bool]$result
                    }
                )
            }
    }

    [List[PSCustomObject]] $results = @()
    $filepath = ".\*.CodeFiles\tests\visuals.json"

    if (!(Test-Path $filepath)) {
        Write-Host "No test files found, skipping..."
        return;
    }

    $tests = Read-Json $filepath
    
    $indent = "  "
    
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

    if ($results.Count -gt 0 -and !$results.Where({ !$_.Passed }).Count) {
        Write-SpectreHost "`npbi-test: [green]✅ all tests passed[/]"
    }

    # return results only if PassThru explicitly specified
    if ($PassThru) { return $results }
}
