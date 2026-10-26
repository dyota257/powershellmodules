# PBI-Test

I am sick of introducing regressions into my Power BI projects. This will be the last time that I push up an older version of the file into production[[1]](#1) (famous last words). Today, I decided to bite the bullet and just _write something_ so that I can start testing for regressions, however little, and I can build up this technology bit by bit. 

## Prerequisites

This method assumes that you're working in PBIP, and using the new PBIR format for reports (not the old report.json).

## Test spec

The test spec document needs to live in `.\*.CodeFiles\tests\visuals.json`.

## Relationship tests

`.\*.CodeFiles\tests\relationships.json` is an array of strings, each the TMDL text of one relationship pasted from `relationships.tmdl` (the `relationship <guid>` header is optional and ignored):

```json
["fromColumn: PurchLine.'Company PurchID Key'\ntoColumn: PurchTable.'Company PurchID Key'"]
```

The model is deserialised (`Get-PbiModel`) and the relationship is matched by from/to column. Property order doesn't matter, but the properties must be exactly those listed, apart from TMDL defaults (`isActive: true`, single direction, many-to-one etc.), which can be omitted. Extra or differing properties, or a missing relationship, fail. Results have `Scope = 'relationship'`.

Here is an example of a test. In this test, on two pages, Project Budgets (A) and Project Budgets (B), I want to make sure that the "Project Number" table visual column is reading from the `Project.ProjectNo` data table column, not `Timesheets.ProjectNo`. Let's say that this was something that I had fixed up in a previous version of the Power BI file ~~that I want to prevent from happening again~~ and I want to know if I'm about to reintroduce it. 

```json
[
    {
        "name": "Project Number on page Project Budgets (on both Version A and Version B)",
        "coordinates": [
            {
                "page": {
                    "id": "ReportSection1111111111111111111111",
                    "name": "Project Budgets (A)"
                },
                "objects": [
                    {
                        "id": "aaaaaaaaaaaaaaaaaaaa",
                        "name": "Main Table",
                        "type": "table"
                    }
                ]
                
            },
            {
                "page": {
                    "id": "ReportSection2222222222222222222222",
                    "name": "Project Budgets (B)"
                },
                "objects": [
                    {
                        "id": "bbbbbbbbbbbbbbbbbbbb",
                        "name": "Main Table",
                        "type": "table"
                    }
                ]
            }
        ],
        "assertions": [
            {
                "description": "Must have 'Project'[ProjectNo] as 'Project Number' column",
                "code": "$projection = $visual.visual.query.queryState.Values.projections.Where({$_.displayName -eq 'Project Number'}); ($projection.field.Column.Expression.SourceRef.Entity -eq 'Project') -and ($projection.queryRef -eq 'Project.ProjectNo')"
            },
            {
                "description": "Must not have 'Timesheets'[JobTaskNo] as Ref column",
                "code": "$projection = $visual.visual.query.queryState.Values.projections.Where({$_.displayName -eq 'Project Number'}); ($projection.field.Column.Expression.SourceRef.Entity -ne 'Timesheets') -and ($projection.queryRef -ne 'Timesheets.ProjectNo')"
            }
        ]
    }
]
```
Here is a generic explanation of each of the fields: 

```json
[
    {
        "name": "The name of the test",
        
        // these are coordinates of the pages and objects to scan through and apply the assertions to       
        "coordinates": [
            {
                "page": {
                    "id": "Right-click \"Copy Object Name\" in Power BI to get the exact GUID of this",
                    "name": "The name of the page. The code doesn't look at this so it doesn't need to be exact"
                },
                "objects": [
                    // you can have multiple objects specified
                    {
                        "id": "Right-click \"Copy Object Name\" in Power BI to get the exact GUID of this",
                        "name": "The name of the page. The code doesn't look at this so it doesn't need to be exact",
                        "type": "The name of the visual type. The code doesn't look at this so it doesn't need to be exact"
                    }
                ]
                
            }
            // you can have multiple pages and objects
            {
                "page": {
                    "id": "27f76f71c70de3011f40",
                    "name": "Project Budgets (B)"
                },
                "objects": [
                    {
                        "id": "28156bc44acc9f379725",
                        "name": "Main Table",
                        "type": "table"
                    }
                ]
            }
        ],
        "assertions": [
            {
                "description": "The name of the assertion",
                "code": "PowerShell code that will be executed to assert logical statement"
            }
            // can have multiple assertions
        ]
    }
]
```

### Report-level tests

To assert something about the report as a whole (not a specific page or visual), set `"scope": "report"` and leave out `coordinates`. The assertions run once against `definition\report.json`, which is available as `$target`.

```json
{
    "name": "Filter pane is visible and collapsed",
    "scope": "report",
    "assertions": [
        {
            "description": "Filter pane visible",
            "code": ["$target.objects.outspacePane[0].properties.visible.expr.Literal.Value -eq 'true'"]
        },
        {
            "description": "Filter pane collapsed",
            "code": ["$target.objects.outspacePane[0].properties.expanded.expr.Literal.Value -eq 'false'"]
        }
    ]
}
```

`scope` is optional. If you leave it out, the test is a visual test (the `coordinates` format above). In visual tests `$target` is the parsed `visual.json`. The older name `$visual` still works.

`code` can be a single string or an array of strings (joined together).

## Test Runner
The PowerShell script that runs this will look for the `visuals.json` in the `\tests` folder. With `-PassThru`, each result has a `Scope` (`visual` or `report`); `PageId`, `VisualId` etc. are blank for report tests. The listing below is the original version and doesn't show the `scope` handling; see `pbi-test.ps1` for the current code.

The script prints out results in the console, and it also passes a data object if `-PassThru` is specified. This is to that other functions downstream can pick up on the test results. 

```powershell
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
        [string[]] $strings
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
    
        Write-Host '' # end with a newline
    }
    
    [List[PSCustomObject]] $results = @()
    $filepath = ".\*.CodeFiles\tests\visuals.json"

    if (!(Test-Path $filepath)) {
        Write-Host "No test files found, skipping..."
        break;
    }

    $tests = Read-Json $filepath

    
    
    $indent = "  "
    
    $tests |
        ForEach-Object {
            $testName = $_.name
            # identify the test that is being run
    
            Console-Print "Running test ", "$($_.name)#Yellow"
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
                                    $sb = [scriptblock]::Create($_.code)
                                    $result = & $sb
                                    $resultIcon = if ($result) { '✅' } else { '❌' }
                                    Write-Host "$indent$indent$resultIcon $($_.description)" 

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

```

## So what? 

I have a PowerShell command in my modules called `pbi-ripandcommit` (aliased as `rnc`). It rips out all of the code and writes it into text, and them makes a git commit. 

I've now hooked in this test into `pbi-ripandcommit` so that it stops the commit if it detects any failed tests'. 

## Review of prior art: 
* There is [fab-inspector](https://github.com/NatVanG/fab-inspector/tree/main), but this is not for regression testing of specific visuals, but rather for enforcing report-wide rules. 

## Footnotes
<span id="1">[1]</span> _How about some discipline huh? What about downloading the file from the workspace, BEFORE making changes?_