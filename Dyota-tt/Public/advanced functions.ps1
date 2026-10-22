using namespace System.Collections

function tt-summary ([int] $last) {
    if ($last -eq 0) { 
        $last = 5
    } else { 
        $last
    }

    $table = tt-get |
        ? {
            # don't include tasks which have not finished yet
            $_.end -ne $null
        } |
        % {
            $clientPrefix = if ($_.client -ne '') { "$($_.client): " } else { '' }
        
            $_.clientProject = "$clientPrefix$($_.project)"

            $_
        }
    
    $longestClientLength = $table | % clientProject | sort length -Descending | select -first 1 | % length
    
    $table |
        group {(get-date $_.start).date} |
        select -Last $last |
        % {
            Write-Host (get-date $_.Name).ToLongDateString() -ForegroundColor Green
            
            [System.Timespan] $totalTime = 0 # for the whole day
            [Generic.List[hashtable]] $summary = @() # set up a separate hashtable list to sort them by duration later
            
            $_.group |
                group clientProject |
                % {
                    [System.Timespan] $hours = 0
                    $_.group |
                        % {
                            $start = get-date $_.start
                            $end = get-date $_.end
                            $duration = if ($null -ne $_.end) {
                                $end - $start
                            } else {
                                # for tasks in progress, count up to now
                                (get-date) - $start
                            }
                            $hours += $duration
                        }
                    
                    $totalTime += $hours
                    
                    [hashtable] $entry = @{ clientProject = $_.name; duration = $hours }

                    [void]$summary.Add( $entry )

                }

            $summary |
                sort duration -Descending |
                % {
                    $hours = $_.duration
                    Write-Host $_.clientProject.PadRight($longestClientLength, ' ') $hours.Hours : $($hours.Minutes).ToString().PadLeft(2, '0')
                }

            # write out time summary per day
            Write-Host ('Total time').PadRight($longestClientLength, ' ') $totalTime.Hours : $($totalTime.Minutes).ToString().PadLeft(2, '0') -ForegroundColor Green
            Write-Host ''
        }
}

function tt-again ([switch] $before) {
    [ArrayList] $tt = tt-get
    
    $lasttask = if ($before) {
        $tt[-2]
    } else {
        $tt[-1]
    }

    tt-start -name $lasttask.name -project $lasttask.project -client $lasttask.client -role $lasttask.role
}

function tt-unend {

    # this is to "un-end" the most recent entry
    # often, I stop the clock, but the I remember that there's "just one more thing"

    # get the last entry
    # as hashtable because it's easier to check for properties

    $tt = tt-get

    [hashtable] $lastTask = $tt | 
        select -last 1

    if ( $lastTask.ContainsKey('end') ) {
        # remove the 'end' property
        $lastTask.Remove('end')

        # replace the last task
        $tt[-1] = $lastTask

        # convert to ndjson and write back
        $tt |
            % {
                $_ | ConvertTo-Json -Compress
            } |
            Out-File $env:ttfile

    } else {
        Write-Host "You haven't finished this task yet; nothing to unend"
    }
}

function tt-hours {
    [Timespan] $hours = 0

    tt-get |
        ? {
            # pick up only the entries for today
            (get-date $_.start -format "yyyy-MM-dd") -eq (get-date -format "yyyy-MM-dd")
        } |
        % {
            # collect up all the durations

            $end = if ($_.ContainsKey('end')) {
                # for most thing, they will have ended
                (get-date $_.end)
            } else {
                # however, if there's a task happening right now, need to pick up on the time right now
                (get-date)
            }

            $_.duration =  $end - (get-date $_.start)
            $hours += $_.duration
        } 

    # hours since 9am

    # has the day ended yet? 

    $hoursSinceNine = if ( (get-date) -gt "5pm" ) {
        ((get-date "17:00") - (get-date "09:00"))
    } else {
        ((get-date) - (get-date "09:00"))
    }
    

    Write-Host "Hours logged today: $($hours.hours):$($hours.minutes.ToString().PadLeft(2, "0"))" -ForegroundColor Red -NoNewline
    Write-Host " ($($hoursSinceNine.Hours):$($hoursSinceNine.Minutes.ToString().PadLeft(2, "0")))" -ForegroundColor Green -NoNewline
    Write-Host " ($(($hours.TotalHours/$hoursSinceNine.TotalHours).ToString("0.0%")))" -ForegroundColor Green -NoNewline
}

function tt-check (
    [string] $client,
    [string] $project
){
    # check hours spent on a project to date
    if ([string]::IsNullOrEmpty($client)) {
        $client = tt-get | 
            % client | 
            ? { $_ -ne '' } |
            select -unique -CaseInsensitive | 
            sort | 
            Read-SpectreSelection -PageSize 10
    }
    
    if ([string]::IsNullOrEmpty($project)) {
        $project = tt-get | 
            ? { $_.client -eq $client } | 
            % project | 
            select -unique -CaseInsensitive | 
            sort | 
            Read-SpectreSelection -PageSize 10
    }
    
    $records = tt-get | 
        ? { 
            ($_.client -eq $client) -and 
            ($_.project -eq $project) -and 
            ($_.end -ne $null )
        }

    $sum = $records |
        % { (get-date $_.end) - (get-date $_.start) } | 
        select totalhours | 
        measure totalhours -sum | 
        % Sum

    # $sum
    $sum = [Math]::Round($sum, 2)

    $earliestDate = get-date ($records | % start | sort | select -first 1) -Format "yyyy-MM-dd"

    Write-SpectreHost "Hours for [yellow]$client $project[/], since [yellow]$earliestDate[/]`: $sum"
}

Export-ModuleMember @(
    'tt-summary'
    'tt-again'
    'tt-unend'
    'tt-hours'
    'tt-check'
)