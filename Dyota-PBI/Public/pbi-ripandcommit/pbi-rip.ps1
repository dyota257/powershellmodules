function pbi-rip ([string] $path) {

    # check if there is a .pbip file in current directory
    $hasPbip = (Get-ChildItem *.pbip).Count -ne 0

    $path = if ($null -ne $path -and '' -ne $path) {
        $path
    } elseif ($hasPbip) {
        (Get-Location).path
    } else {
        Write-Host "There is no PBIP project here; aborting"
        break;
    }

    pbi-ripCode $path
}