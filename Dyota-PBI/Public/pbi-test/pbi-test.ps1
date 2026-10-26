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

    function Write-Outcome ($passed, $description) {
        $description = $description.replace('[', '[[').replace(']', ']]')
        if ($passed) {
            Print-Verbose "$indent$indent [green]✅[/] $description"
        } else {
            Write-SpectreHost "$indent$indent [red]❌[/] $description"
        }
    }

    [List[PSCustomObject]] $results = @()
    $indent = "  "

    $ranVisuals = Test-Visuals
    $ranRelationships = Test-Relationships

    if (!$ranVisuals -and !$ranRelationships) {
        Write-Host "No test files found, skipping..."
        return
    }

    if ($results.Count -gt 0 -and !$results.Where({ !$_.Passed }).Count) {
        Write-SpectreHost "`npbi-test: [green]✅ all tests passed[/]"
    }

    # return results only if PassThru explicitly specified
    if ($PassThru) { return $results }
}
