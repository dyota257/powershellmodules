# this function takes the path of the PROJECT and then fetches the model as a PowerShell object

function Get-PbiModel ($path) {
    
    # First, check what kind of model it is, whether it is a TMDL directory or a single model.bim

    Write-Host "Checking if this is TMDL or model.bim..."

    $projectName = $path.split('\')[-1]
    # $projectName = Split-Path -Leaf $path

    
    if (pbi-tmdlCheckFormat $path ) {
        
        # TMDL directory

        Write-Host "This is a TMDL semantic data model"

        $modelDirectory = "$path\$projectName.SemanticModel\definition"
        $model = pbi-tmdlDsrl $modelDirectory

    } else {

        Write-Host "This is a model.bim semantic data model"

        $modelFile =  "$path\$projectName.SemanticModel\model.bim"
        # put in argument -AshHashTable because some property names are empty strings (e.g. "": { ... })
        # $model = cat $modelFile | ConvertFrom-Json -AsHashtable
        $model = pbi-jsonDsrl $modelFile

    }

    return $model

}