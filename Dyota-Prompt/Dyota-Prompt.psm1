function currentlyWorkingOn {
    $currentTask = (Get-Content $env:ttfile) | 
        Select-Object -Last 1 | # this is possible because source file is in NDJSON
        ConvertFrom-Json

    $currentTaskName    = $currentTask.name
    $currentTaskStart   = $currentTask.start
    $currentTaskEnd     = $currentTask.end

    $duration   = ((Get-Date) - (Get-Date $currentTaskStart))
    $hours      = $duration.Hours
    $minutes    = $duration.Minutes

    $currentlyWorking = $null -eq ($currentTaskEnd)
    
    $hoursText = if ($hours -gt 1) { 
        "$hours hours "     # more than 1 hour
    } elseif ($hours -eq 1) {
        "$hours hour "      # exactly 1 hour
    }                       # if less than 1 hour, then don't mention it

    if ($currentlyWorking) {
        Write-Host "On: $currentTaskName ($hoursText$minutes minutes)" -ForegroundColor Red
    }
}

function timestamp ($promptColour) {
    $time = (Get-Date -Format "HH:mm")
    Write-Host "["$time" ]" -ForegroundColor $promptColour
}

function virtualDesktopNameNNL {
    $registry = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops'
    $virtualDesktop = try {
        [guid]::new([byte[]](Get-ItemPropertyValue $registry 'CurrentVirtualDesktop')) | 
        % { 
            Get-ItemPropertyValue "$registry\Desktops\{$_}" Name -ErrorAction SilentlyContinue 
        }    
    }
    catch { '' }

    if (($virtualDesktop) -ne '') {
        Write-Host "|$($virtualDesktop.ToUpper())| "  -ForegroundColor Blue  -NoNewline
    }
}

function currentDirectoryNNL ($promptColour) {
    $cwd    = $ExecutionContext.SessionState.Path.CurrentLocation.Path.Split("\")
    $curdir = $cwd[-2]+"\"+$cwd[-1]
    $drive  = $ExecutionContext.SessionState.Drive.Current.Name+":"
    if($cwd.Length -eq 2) {
        $curdir = "\"+$cwd[-1]
    }
    
    Write-Host "[$drive $curdir] " -ForegroundColor $promptColour -NoNewline
}

function projecttypeNNL {
    $ispbipfolder = ((dir *.pbip).Count -gt 0)
    
    if ($ispbipfolder) { 
        # Write-Host "[pbip] " -ForegroundColor Yellow -NoNewline 
        Write-Host "🟨 " -ForegroundColor Yellow -NoNewline 
    }

    $issqlfolder = if ((Test-Path '.\.vscode\settings.json')) {
        (cat '.\.vscode\settings.json' | ConvertFrom-Json).'workbench.colorTheme' -eq 'dk bee'
    } else {$null}
    
    if ($issqlfolder) { 
        # Write-Host "[sql] " -ForegroundColor Magenta -NoNewline 
        Write-Host "🟪 " -ForegroundColor Magenta -NoNewline 
    }
    
}

function gitBranch {
    if (Test-Path .git) {
        if ($null -eq (git branch)) {
            # this is if the repo had just been initialised, and there are no branches
            $currentBranch =  "~"
        } else {
            $currentBranch = ((git branch) | ? { $_.StartsWith('*') } )
            $currentBranch = if ($currentBranch.contains('master') ) {
                # $currentBranch.replace('*','🪵')
                $currentBranch.replace('*','🡹').replace('master', '')
                # write-host '🢰 master' -ForegroundColor Green
            } else {
                # $currentBranch.replace('*', '🌿')
                $currentBranch.replace('*', '🢰')
            }
        }

        Write-Host "[$currentBranch]" -ForegroundColor Green -NoNewline
    }
}

function promptOutput {
    $global:mode = Get-Content "$($env:HOMEPATH)\.files\mode.txt"

    $promptColour = switch ($global:mode) {
        'work' { 'Cyan' }
        'home' { 'Magenta' }
    }

    $mode = "[$($global:mode.ToUpper())]"

    timestamp $promptColour
    currentlyWorkingOn
    Write-Host "`n"
    virtualDesktopNameNNL
    currentDirectoryNNL $promptColour
    projecttypeNNL
    
    gitBranch
    "`n> "
}

Export-ModuleMember promptOutput