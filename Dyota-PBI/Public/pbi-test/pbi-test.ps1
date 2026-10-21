using namespace System.Collections.Generic

function pbi-test (
    [switch] $PassThru
){

    function Read-Json ($path) {
        Get-Content $path | ConvertFrom-Json -Depth 20
    }
    
    function Console-Log ($text) {
        # comment out this command to deactivate all of the "console-logs"
        # Write-Host -ForegroundColor DarkGray ">> $text"
    }
    
    function Console-Print (
        [string[]] $strings,
        [switch] $NoNewLine

    ) {
        # colour formatting on multiple Write-Host commands
        $strings |
            ForEach-Object {
                $text = $_.split('#')[0]
                $colour = $_.split('#')[1]
                
                if ($null -ne $colour) {
                    Write-Host $text -NoNewline -ForegroundColor $colour
                } else {
                    Write-Host $text -NoNewline
                }
            }
    
        if (!$NoNewLine) {
            Write-Host "" # end with a newline
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
    
            Console-Print "`nRunning test ", "$($_.name)#Yellow"
            Console-Log "Running through all pages..."
    
            $coordinates = $_.coordinates
    
            $assertions = $_.assertions
    
            $coordinates |
                ForEach-Object {
                    # one page
                    $page = $_.page.id
                    $pageName = $_.page.name
                    Console-Print "Checking page ", "$pageName...#yellow"
    
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
    
                            Console-Print "$indent Checking $objectType ", "$objectName#Yellow"
                            
                            $assertions |
                                ForEach-Object {
                                    $code = $_.code -join ""
                                    $sb = [scriptblock]::Create($code)
                                    $result = & $sb
                                    
                                    Write-Host "$indent$indent" -NoNewline
                                    if ($result) { Console-Print '✅#Green' -NoNewLine
                                    } else { Console-Print '❌#Red' -NoNewLine }
                                    Write-Host " $($_.description)" 

                                    # return this object is PassThru explicitly specified
                                    if ($PassThru) {
                                        $results.Add(
                                            [PSCustomObject]@{
                                                TestName    = $testName
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
                        }
                }
        }

    if ($PassThru) { return $results }
}
