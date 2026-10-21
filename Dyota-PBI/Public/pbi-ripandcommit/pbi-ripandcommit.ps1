function pbi-ripandcommit (
    [Parameter(Mandatory)]
    [string] $comment
) {
    if ($null -ne $comment) {
        $testResults = pbi-test -PassThru

        if ( 
            ($testResults.Where({ !($_.Passed) }).Count -eq 0 ) -or
            ($null -eq $testResults)
        ) {
            pbi-rip
            git add .
            git commit -m $comment
            done "commit: $comment" -tt
            pbi-docs
        } else {
            Write-Host -ForegroundColor Red "Test failed! Did not rip, did not commit"
        }
    } else {
        Write-Host "Must provide a commit comment"
    }
}
