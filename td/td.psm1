$script:td = "$env:DOCUMENTS\td.txt"

$script:dateformat = 'yy-MM-dd'
function td-edit {
    # Change all line endings to LF only instead of CRLF
    # ((Get-Content $td) -replace "`r`n", "`n") | Set-Content $td
    nvim $td;
    
    # after exiting...
    Clear-Host;
    td;
}

function td-print {
    s 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge' $td
}

function td-displayprocess ([string] $textrow) {
    if ($textrow[-1] -eq '@') {
        $length = $_.length
        $textrow = $textrow.Substring(0, $length-1) # these will have a @ indicator on the end; take this off
    }
    
    $parts = $textrow.split('#')
    
    if ($parts.Count -gt 1) { 
        $task = $parts[1].replace('[ ]', '')
        $daysAgo = ((get-date) - (
            # get-date  -Format $script:dateformat 
            [System.DateTime]::ParseExact($parts[0], $script:dateformat, $null)
        )).days

        $daysAgoDisplay = switch ($daysAgo) {
            0 { "$("today".PadLeft(12))" }
            1 { "$("yesterday".PadLeft(12))"}
            default { "$($daysAgo.ToString().PadLeft(3)) days ago" }
        }

        Write-Host $daysAgoDisplay -ForegroundColor DarkGray -NoNewline
        
        if ($task[-1] -eq "!") {
            Write-Host -ForegroundColor Yellow $task
        } else {
            Write-Host $task
        }
    } else {
        $textrow 
    }
}

function td-display-short {
    Get-Content $td | 
        ? { $_[-1] -eq '@' } |                               # only pick up text rows with a ! or @ at the end, marked for important, and short-term doing
        sort { get-date -date $_.split('#')[0] -format $script:dateformat } -desc |     # sort newest to oldest
        % { td-displayprocess $_  }                                             # make it look nicer on the terminal
}
function td-display-all {
    Clear-Host;
    
    Get-Content $td | 
        % { td-displayprocess $_ }  # make it look nicer on the terminal

    $countTasks = (Get-Content $td | ? { $_ -like '*[ ]*' }).length

    Write-Host "($countTasks items in todo list)`n"
}

function td-add ([string] $thing) {
    $projectPrefix = if ($tt) {
        $task = (tt-get)[-1]
        $client = if ($task.client -ne '') { $task.client } else { "(No client)" }
        "[$($client): $($task.project)]"
    } else {
        $null
    }

    $date = (Get-Date).ToString($script:dateformat)

    $body = "$projectPrefix $thing".Trim() # guard against errant space in the middle
    
    "$date# $body" | 
        Add-Content -Path $td -Encoding "UTF8"
}

function td {
    [CmdletBinding()]
    param(
        [string] $thing,
        [switch] $all,
        [switch] $edit,
        [switch] $print,
        [switch] $tt
    )

    switch ($true) {
        $edit                   { td-edit }
        $print                  { td-print }
        ($thing.length -ne 0)   { td-add $thing }
        $all                    { td-display-all }
        default                 { td-display-short }
    }

}

Export-ModuleMember -Function 'td'
