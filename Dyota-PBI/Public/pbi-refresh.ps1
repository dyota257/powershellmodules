function pbi-refresh {
    <#
    .SYNOPSIS
        Refresh selected tables in an open Power BI Desktop model.
    .EXAMPLE
        pbi-refresh                                  # pick tables interactively
        pbi-refresh -Tables tblPnlMapping, tblPnlLeaves
    #>
    param(
        [string[]] $Tables,
        [int] $Port
    )

    $ErrorActionPreference = 'Stop'

    # TOM is loaded by Dyota-PBI.psm1. If another module (e.g. SqlServer) got an older version in
    # first, .NET can't hold two, so re-run in a clean process.
    if (-not ('Microsoft.AnalysisServices.Tabular.Server' -as [type])) {
        $call = 'pbi-refresh'
        if ($Tables) { $call += ' -Tables ' + (($Tables | ForEach-Object { "'$($_ -replace "'", "''")'" }) -join ',') }
        if ($Port) { $call += " -Port $Port" }
        & (Get-Process -Id $PID).Path -NoProfile -Command "Import-Module '$PSScriptRoot\..\Dyota-PBI.psd1' -DisableNameChecking -WarningAction SilentlyContinue; $call"
        return
    }

    Import-Module PwshSpectreConsole

    if (-not $Port) {
        $instances = foreach ($proc in Get-Process msmdsrv -ErrorAction SilentlyContinue) {
            $listen = netstat -ano | Where-Object { $_ -match 'LISTENING' -and $_ -match "\s$($proc.Id)$" -and $_ -match '127\.0\.0\.1:(\d+)' } | Select-Object -First 1
            if ($listen -match '127\.0\.0\.1:(\d+)') {
                $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").ParentProcessId
                $title = (Get-Process -Id $parentId -ErrorAction SilentlyContinue).MainWindowTitle
                [pscustomobject]@{ Port = [int]$Matches[1]; Label = "$(if ($title) { $title } else { 'Power BI Desktop' }) (port $($Matches[1]))" }
            }
        }
        if (-not $instances) { throw 'No Power BI Desktop instance found.' }
        $Port = if (@($instances).Count -eq 1) { $instances.Port }
                else { (Read-SpectreSelection -Message 'Which model?' -Choices $instances -ChoiceLabelProperty Label).Port }
    }

    $server = [Microsoft.AnalysisServices.Tabular.Server]::new()
    $server.Connect("localhost:$Port")

    try {
        $db = $server.Databases[0]

        if (-not $Tables) {
            $choices = $db.Model.Tables | Where-Object { -not $_.IsPrivate -and -not $_.ShowAsVariationsOnly } | Sort-Object Name | ForEach-Object {
                $last = ($_.Partitions.RefreshedTime | Measure-Object -Maximum).Maximum
                $when = if ($last -and $last.Year -gt 1900) { $last.ToLocalTime().ToString('d MMM HH:mm') } else { 'never' }
                [pscustomobject]@{ Name = $_.Name; Label = "$(Get-SpectreEscapedText $_.Name) [grey]($when)[/]" }
            }

            $Tables = (Read-SpectreMultiSelection -Message 'Tables to refresh' -Choices $choices -ChoiceLabelProperty Label -PageSize 20).Name
            if (-not $Tables) { Write-SpectreHost '[yellow]Nothing selected.[/]'; return }
        }

        $tmsl = @{ refresh = @{ type = 'full'; objects = @($Tables | ForEach-Object { @{ database = $db.Name; table = $_ } }) } } | ConvertTo-Json -Depth 5

        $timer = [Diagnostics.Stopwatch]::StartNew()
        $results = Invoke-SpectreCommandWithStatus -Title "Refreshing $($Tables -join ', ')" -ScriptBlock { $server.Execute($tmsl) }

        $messages = $results | ForEach-Object { $_.Messages }
        $errors = @($messages | Where-Object { $_ -is [Microsoft.AnalysisServices.XmlaError] })
        foreach ($m in $messages) {
            $tag = if ($m -is [Microsoft.AnalysisServices.XmlaError]) { '[red]Error:[/]' } else { '[yellow]Warning:[/]' }
            Write-SpectreHost "$tag $(Get-SpectreEscapedText $m.Description)"
        }
        if (-not $errors.Count) {
            Write-SpectreHost "[green]Refreshed $($Tables.Count) table(s) in $([int]$timer.Elapsed.TotalSeconds)s.[/]"
        }
    }
    finally {
        $server.Disconnect()
    }
}
