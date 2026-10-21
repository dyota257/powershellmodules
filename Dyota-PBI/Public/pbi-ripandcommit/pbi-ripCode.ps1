function pbi-ripCode ($path) {
    # takes a .pbip folder, rips out all of the PQ and DAX, and stores it inside the same folder as $projectname.CodeFiles

    $projectName = $path.split('\')[-1]
    Write-Host -ForegroundColor Yellow "Ripping " -NoNewline
    Write-Host -ForegroundColor Green "$projectName"

    $model = Get-PbiModel $path
    
    if (($null -ne $model) -eq $true) {
        # put in argument -AshHashTable because some property names are empty strings (e.g. "": { ... })
        Write-Host -ForegroundColor Cyan "Reading model.bim... "
        Export-PowerQuery "$path\$projectName.CodeFiles\pq" $model
        Export-DAX "$path\$projectName.CodeFiles\dax" $model
        Export-RLS "$path\$projectName.CodeFiles" $model
        Export-Relationships "$path\$projectName.CodeFiles" $model
    }

    $reportFormat = Get-PBIPReportFormat $path
    
    switch ($reportFormat) {
        # original report.json
        0 {
            $reportFile = "$path\$projectName.Report\report.json"

            if ((Test-Path $reportFile) -eq $true) {
                # put in argument -AshHashTable because some property names are empty strings (e.g. "": { ... })
                Write-Host -ForegroundColor Cyan "Reading report.json... "

                $report = cat $reportFile | ConvertFrom-Json -AsHashtable
                Export-DAXReport "$path\$projectName.CodeFiles\dax" $report
                Export-Report "$path\$projectName.CodeFiles\report" $report
                Export-Pages "$path\$projectName.CodeFiles\" $report
            }
        }

        # PBIR format
        1 {
            Export-Pages-PBIR "$path\$projectName.CodeFiles\" "$path\$projectName.Report"
        }
    }
}