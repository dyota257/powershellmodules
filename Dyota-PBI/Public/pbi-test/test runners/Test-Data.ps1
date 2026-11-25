# Test runner for tests\data\<case>\query.dax + reference.csv. Called by pbi-test -Data, which supplies the shared
# helpers and the $results variable through dynamic scope. Queries Power BI Desktop, or the published model
# with -Workspace. Returns $false if there is no tests\data folder.

function Test-Data ([string] $Filter = '*', [int] $Port, [switch] $Workspace) {
    $root = (Get-Location).Path
    if (!(Test-Path -Path (Join-Path $root '*.CodeFiles\tests\data'))) {
        Write-Warning 'pbi-test -Data: no *.CodeFiles\tests\data folder; no data tests run.'
        return $false
    }
    Print-Verbose "`nRunning test [yellow]data[/]"

    function Add-DataResult ($name, $passed, $description) {
        $results.Add([PSCustomObject]@{
            TestName = $name; Scope = 'data'; PageId = $null; PageName = $null
            VisualId = $null; VisualName = $null; VisualType = $null
            Description = $description; Passed = [bool] $passed
        })
    }

    try {
        if ($Workspace) {
            $pick = Select-PbiServiceModel -Root $root
            Connect-PbiFabric -TenantId $pick.Workspace.TenantId
            $workspaceId = $pick.Workspace.Id
            $modelId = Resolve-PbiServiceModelId -Workspace $pick.Workspace -Model $pick.Model
            Write-SpectreHost "Data tests against [blue]$(Get-SpectreEscapedText $pick.Model.name)[/] in $(Get-SpectreEscapedText $pick.Workspace.Label)"
            $query = { param($dax) Invoke-PbiServiceQuery -WorkspaceId $workspaceId -ModelId $modelId -Query $dax }
        }
        else {
            if (!$Port) { $Port = (Select-PbiDesktopInstance -Root $root -RequireMatch).Port }
            $query = { param($dax) Invoke-PbiDesktopQuery -Port $Port -Query $dax }
        }
    }
    catch {
        # Couldn't reach a model: fail rather than skip, so callers like rnct don't commit untested.
        Write-SpectreHost "[red]data tests not run: $(Get-SpectreEscapedText $_.Exception.Message)[/]"
        Add-DataResult 'data' $false "data tests not run: $($_.Exception.Message)"
        return $true
    }

    foreach ($r in Invoke-PbiDataTests -Root $root -Query $query -Filter $Filter -Detail:$verbose) {
        $description = if ($r.Passed) { "$($r.Case) ($($r.Cells) cells)" } else { "$($r.Case): $($r.Errors -join '; ')" }
        Add-DataResult $r.Case $r.Passed $description
    }
    return $true
}
