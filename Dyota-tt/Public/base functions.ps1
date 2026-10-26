using namespace System.Collections


function tt {
    $tt = tt-get
    $lasttask = $tt[-1]

    $task = $lasttask.name
    $project = $lasttask.project
    $startTime = (Get-Date $lasttask.start).ToString("hh:mm")
    $finishTime = try { (Get-Date $lasttask.end).ToString("hh:mm") } catch { $null }  # end time could be null

    if ($null -ne $lasttask.end) {
        Write-SpectreHost "Not working on anything. Last worked on [red]$task ($project)[/], finished at [red]$finishTime[/]."
    }
    else {
        Write-SpectreHost "Currently working on [yellow]$task[/] since [yellow]$startTime[/]."
    }

    tt-hours
}

function tt-get {
    # ttfile is a ndjson file (newline-delimited json)
    # convert as hashtable because it will be easier to work with later compared to pscustomobjects
    return (Get-Content $env:ttfile | ConvertFrom-Json -AsHashtable)
}

function tt-start {
    param (
        # [Parameter(Mandatory)]
        [string] $name,

        # [Parameter(Mandatory)]
        [string] $project,

        # [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $client,

        # [Parameter(Mandatory)]
        [string] $role,

        [switch] $billable
    )
    
    [hashtable] $lasttask = (tt-get)[-1]

    # if there is a task already in progress, disallow making a new task

    if (-not $lasttask.ContainsKey('end')) {
        Write-Host  You are still working on `"$($lasttask.name)`". Finish this one before starting another task. 
        break
    }
    else {

        while ([string]::IsNullOrEmpty($client)) { $client = Read-SpectreText -Message 'Client: ' -DefaultAnswer 'iCatalyst' }
        while ([string]::IsNullOrEmpty($project)) { $project = Read-SpectreText -Message 'Project: ' }
        
        
        
        while ([string]::IsNullOrEmpty($name)) {
            # stay on this until the name is filled out
            $name = Read-SpectreText -Message 'Task: '
        }
        while ([string]::IsNullOrEmpty($role)) {$role = Read-SpectreText -Message 'Role:' -DefaultAnswer 'bi'}
        
        

        # if the new task doesn't have a name, prompt for a name and break
        if (($null -eq $name -or ($name.length -eq 0))) {
            Write-Host  "You need a name for your new task"
            break
        }

        $star = if ($billable) { "*" } else { '' }

        $newtask = [ordered] @{
            "role"    = $role;
            "client"  = $client;
            "project" = $project;
            "name"    = "$star$name";
            "start"   = (Get-Date -Format "yyyy-MM-ddTHH:mm")
        }

    }
    
    $newtask |
        ConvertTo-Json -Compress |
        Out-File -Append $env:ttfile
}


function tt-end ([string] $note) {
    $tt = tt-get
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm"

    [hashtable] $lastTask = $tt[-1]
    # If the last entry already has a end time, then must be not working on anything at the moment. 
    if ($lastTask.ContainsKey('end')) {
        Write-Host 'Not working on anything at the moment';
        break
    }

    # if "end" is not an existing property of this last object, then make one
    $lastTask.end = $timestamp
    
    # if there is a note, automatically write into "done.txt"
    # requires "done" ps module
    if ($note -ne '') {
        $client = if ($lastTask.client -ne '') { $lastTask.client } else { "(No client)" }
        $project = $($lastTask.project)
        done "[$($client): $project] $note"
    }

    $tt | 
        % { $_ | ConvertTo-Json -Compress } | # this makes the file into ndjson format
        Out-File $env:ttfile

    $duration = ((Get-Date $lastTask.end) - (Get-Date $lastTask.start))
    $hours = $duration.Hours
    $minutes = $duration.Minutes

    Write-Host -ForegroundColor Red "$(if ($hours -gt 1) { "$hours hours " } elseif ($hours -eq 1) { "$hours hour " })$minutes minutes"

    tt-hours
}

function tt-edit ([switch] $vd){
    if ($vd) {
        visidata $env:ttfile
    } else {
        nvim $env:ttfile
    }
}

Export-ModuleMember @(
    'tt'
    'tt-get' # expose this because function done uses this
    'tt-start'
    'tt-end'
    'tt-edit'
)