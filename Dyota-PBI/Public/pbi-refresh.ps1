function pbi-refresh {
    <#
    .SYNOPSIS
        Refresh selected tables in an open Power BI Desktop model, or (-Workspace) trigger a
        data refresh of a published semantic model.
    .DESCRIPTION
        The choices (instance, tables, workspace, model) are made in the current terminal, then the
        refresh is watched in a new pwsh window, freeing the terminal. That window stays open and
        shows the result, elapsed time and any errors, and flashes the taskbar when done.

        -Workspace runs from a PBIP folder with a *.CodeFiles\structure.json
        (tenant[].workspace[].model[]). Prompts for the workspace and model when there are
        several and triggers the refresh via the Power BI REST API. Models without a
        pbiModelDatabaseName are looked up by name in the workspace. With -Tables, an enhanced
        refresh of just those tables is requested (Premium/Fabric capacity). The new window
        reuses the saved Az login (Az context autosave must be on).
    .EXAMPLE
        pbi-refresh                                  # pick tables interactively
        pbi-refresh -Tables tblPnlMapping, tblPnlLeaves
        pbi-refresh -All                             # refresh every table in the Desktop model
        pbi-refresh -Workspace                       # refresh a published model from structure.json
        pbi-refresh -Workspace -Tables tblPnlMapping
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Existing Dyota-PBI public command naming convention.')]
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [string[]] $Tables,
        [Parameter(ParameterSetName = 'Local')] [int] $Port,
        [Parameter(ParameterSetName = 'Local')] [switch] $All,
        [Parameter(Mandatory, ParameterSetName = 'Workspace')] [switch] $Workspace
    )

    $ErrorActionPreference = 'Stop'

    if ($Workspace) {
        Import-Module PwshSpectreConsole
        $pick = Select-PbiServiceModel -Root (Get-Location).Path
        $target = $pick.Workspace
        Connect-PbiFabric -TenantId $target.TenantId
        $modelId = Resolve-PbiServiceModelId -Workspace $target -Model $pick.Model
        Start-PbiServiceRefresh -Workspace $target -ModelId $modelId -Name $pick.Model.name -Tables $Tables
        return
    }

    $tablesArg = if ($Tables) { ' -Tables ' + (($Tables | ForEach-Object { ConvertTo-PbiQuoted $_ }) -join ',') }

    # TOM is loaded by Dyota-PBI.psm1. If another module (e.g. SqlServer) got an older version in
    # first, .NET can't hold two, so re-run the picker in a clean process.
    if (-not ('Microsoft.AnalysisServices.Tabular.Server' -as [type])) {
        $call = "pbi-refresh$tablesArg"
        if ($Port) { $call += " -Port $Port" }
        if ($All) { $call += ' -All' }
        & (Get-Process -Id $PID).Path -NoProfile -Command "Import-Module $(ConvertTo-PbiQuoted "$PSScriptRoot\..\Dyota-PBI.psd1") -DisableNameChecking -WarningAction SilentlyContinue; $call"
        return
    }

    Import-Module PwshSpectreConsole

    $instanceName = "port $Port"
    if (-not $Port) {
        $instance = Select-PbiDesktopInstance -Root (Get-Location).Path
        $Port = $instance.Port
        $instanceName = $instance.Name
    }

    if ($All) {
        Start-PbiRefreshWindow "$instanceName - all tables" "Invoke-PbiDesktopRefresh -Port $Port -Name $(ConvertTo-PbiQuoted $instanceName) -All"
        Write-SpectreHost 'Refreshing [blue]all tables[/] in a new window.'
        return
    }

    if (-not $Tables) {
        $server = [Microsoft.AnalysisServices.Tabular.Server]::new()
        $server.Connect("localhost:$Port")
        try {
            $choices = $server.Databases[0].Model.Tables | Where-Object { -not $_.IsPrivate -and -not $_.ShowAsVariationsOnly } | Sort-Object Name | ForEach-Object {
                $last = ($_.Partitions.RefreshedTime | Measure-Object -Maximum).Maximum
                $when = if ($last -and $last.Year -gt 1900) { $last.ToLocalTime().ToString('d MMM HH:mm') } else { 'never' }
                [pscustomobject]@{ Name = $_.Name; Label = "$(Get-SpectreEscapedText $_.Name) [grey]($when)[/]" }
            }
        }
        finally {
            $server.Disconnect()
        }
        $Tables = (Read-SpectreMultiSelection -Message 'Tables to refresh' -Choices $choices -ChoiceLabelProperty Label -PageSize 20).Name
        if (-not $Tables) { Write-SpectreHost '[yellow]Nothing selected.[/]'; return }
        $tablesArg = ' -Tables ' + (($Tables | ForEach-Object { ConvertTo-PbiQuoted $_ }) -join ',')
    }

    Start-PbiRefreshWindow "$instanceName - $($Tables -join ', ')" "Invoke-PbiDesktopRefresh -Port $Port -Name $(ConvertTo-PbiQuoted $instanceName)$tablesArg"
    Write-SpectreHost "Refreshing [blue]$(Get-SpectreEscapedText ($Tables -join ', '))[/] in a new window."
}
