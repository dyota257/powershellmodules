using namespace System.Collections.Generic
using namespace System.Collections.Specialized

function Export-Pages-PBIR ($dest, $reportPath) {
    
    [List[OrderedDictionary]] $dictionary = @()

    $dir = "$reportPath\definition\pages"

    $pagesMaster = cat "$dir\pages.json" |
        convertfrom-json -depth 4 |
        % pageOrder

    dir $dir -Directory |
        % {
            $page = cat "$_\page.json" |
                convertfrom-json 

            [OrderedDictionary] $dictionaryEntry = [ordered] @{
                page = $page.displayName
                show = $page.visibility -eq $null
                guid = $page.name
                path = $_.BaseName
                order = $pagesMaster.IndexOf($page.name)
            }

            [void] $dictionary.Add($dictionaryEntry)
        }

    $json = $dictionary |
        % { [pscustomobject] $_ } | # need to convert to pscustomobject to all property selection
        sort order |
        select -property * -ExcludeProperty order |
        convertto-json -compress

    # # format the json in a friendlier format
    $json.Replace('[{', "[`n`t{").Replace('}]', "}`n]").Replace("},{", "},`n`t{") |
        out-file "$dest\pages.json"

    
    # # For PBIR format, pages are in individual folders under definition/pages/
    # [List[PSCustomObject]] $pages = @()

    # $pagesFolder = "$reportPath\definition\pages"

    # if (!(Test-Path $pagesFolder)) {
    #     Write-Warning "No pages folder found at $pagesFolder"
    #     return
    # }

    # # Read the pages metadata to get page ordering
    # $pagesMetadataPath = "$pagesFolder\pages.json"
    # if (!(Test-Path $pagesMetadataPath)) {
    #     Write-Warning "No pages.json metadata found at $pagesMetadataPath"
    #     return
    # }

    # $pagesMetadata = Get-Content $pagesMetadataPath | ConvertFrom-Json

    # # Iterate through pages in the order defined in pages.json
    # $pagesMetadata.pageOrder |
    #     ForEach-Object {
    #         $pageGuid = $_
    #         $pageJsonPath = "$pagesFolder\$pageGuid\page.json"

    #         if (Test-Path $pageJsonPath) {
    #             $pageData = Get-Content $pageJsonPath | ConvertFrom-Json

    #             $pages.Add(
    #                 [ordered] @{
    #                     page = $pageData.displayName
    #                     show = ($pageData.visibility -ne 'HiddenInViewMode')
    #                 }
    #             )
    #         }
    #     }

    # $pages | ConvertTo-Json > "$dest\pages.json" -Compress
}

