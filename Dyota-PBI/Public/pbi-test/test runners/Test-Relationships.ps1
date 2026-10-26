# Test runner for tests\relationships.json. Called by pbi-test, which supplies the shared helpers
# (Read-Json, Print-Verbose, Write-Outcome) and the $results variable through dynamic scope.
# Returns $false if there is no relationships.json.

function Test-Relationships {
    # TOM defaults; TMDL omits these, so they are dropped before comparing
    $relationshipDefaults = @{
        isactive                   = 'true'
        crossfilteringbehavior     = 'onedirection'
        fromcardinality            = 'many'
        tocardinality              = 'one'
        securityfilteringbehavior  = 'onedirection'
        joinondatebehavior         = 'dateandtime'
        relyonreferentialintegrity = 'false'
    }

    # spec entry (TMDL text, header optional) -> @{ key(lowercase) = value }
    function ConvertFrom-RelationshipSpec ($text) {
        $props = @{}
        foreach ($line in ($text -split '\r?\n')) {
            if ($line -match '^\s*(\w+)\s*:\s*(.*?)\s*$') {
                $props[$Matches[1].ToLower()] = $Matches[2]
            }
        }
        $props
    }

    function Format-Value ($v) { ("$v" -replace "'", '').Trim().ToLower() }

    $filepath = Resolve-Path ".\*.CodeFiles\tests\relationships.json" -ErrorAction SilentlyContinue
    if (!$filepath) { return $false }

    $specs = Read-Json $filepath
    Print-Verbose "`nRunning test [yellow]relationships[/]"

    $relationships = $null
    try {
        $modelPath = Resolve-Path ".\*.SemanticModel\definition"
        $model = pbi-tmdlDsrl $modelPath.Path
        $relationships = $model.Model.Relationships
    } catch {
        Write-SpectreHost "[red]could not load semantic model: $($_.Exception.Message.replace('[','[[').replace(']',']]'))[/]"
    }

    # pad the one-side column so every arrow starts in the same text column
    $leftWidth = ($specs | ForEach-Object { (ConvertFrom-RelationshipSpec $_)['tocolumn'].Length } | Measure-Object -Maximum).Maximum

    foreach ($spec in @($specs)) {
        $want = ConvertFrom-RelationshipSpec $spec
        $from = Format-Value $want['fromcolumn']
        $to = Format-Value $want['tocolumn']
        # tmdl "from" is the many side and "to" is the one side (defaults), so show one --> many, as in the docs
        $fromCard = if ($want['fromcardinality'] -eq 'one') { '1' } else { 'M' }
        $toCard   = if ($want['tocardinality'] -eq 'many') { 'M' } else { '1' }
        $description = "$($want['tocolumn'].PadRight($leftWidth)) ($toCard)───>($fromCard) $($want['fromcolumn'])"
        $problems = @()

        $rel = $relationships | Where-Object {
            $_.FromColumn -and $_.ToColumn -and
            (Format-Value "$($_.FromColumn.Table.Name).$($_.FromColumn.Name)") -eq $from -and
            (Format-Value "$($_.ToColumn.Table.Name).$($_.ToColumn.Name)") -eq $to
        } | Select-Object -First 1

        if (!$rel) {
            $problems += 'not found in model'
        } else {
            $have = @{}
            foreach ($name in $relationshipDefaults.Keys) {
                $prop = $rel.PSObject.Properties | Where-Object { $_.Name -ieq $name }
                if ($prop) {
                    $v = Format-Value $prop.Value
                    if ($v -ne $relationshipDefaults[$name]) { $have[$name] = $v }
                }
            }
            foreach ($k in $have.Keys) {
                if (!$want.ContainsKey($k)) { $problems += "unexpected property $k = $($have[$k])" }
                elseif ((Format-Value $want[$k]) -ne $have[$k]) { $problems += "$k expected $($want[$k]) found $($have[$k])" }
            }
            foreach ($k in $want.Keys) {
                if ($k -in 'fromcolumn', 'tocolumn') { continue }
                if (!$have.ContainsKey($k)) {
                    if (!$relationshipDefaults.ContainsKey($k)) { $problems += "unknown property $k" }
                    elseif ((Format-Value $want[$k]) -ne $relationshipDefaults[$k]) { $problems += "$k expected $($want[$k]) found default $($relationshipDefaults[$k])" }
                }
            }
        }

        $passed = $problems.Count -eq 0
        $shown = if ($passed) { $description } else { "$description ($($problems -join '; '))" }
        Write-Outcome $passed $shown
        $results.Add([PSCustomObject]@{
            TestName = 'relationships'; 
            Scope = 'relationship'; 
            PageId = $null; 
            PageName = $null
            VisualId = $null; 
            VisualName = $null; 
            VisualType = $null
            Description = $shown; 
            Passed = $passed
        })
    }
    return $true
}
