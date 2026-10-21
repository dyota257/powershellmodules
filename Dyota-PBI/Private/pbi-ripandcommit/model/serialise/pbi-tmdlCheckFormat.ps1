# check if the Power BI Project data model is the model.json type or the TMDL type
# it is more reliable to check for the existence of TMDL files rather than checking for the existence of model.bim
# projects that were converted from model.bim to TMDL could still have model.bim in there


function pbi-tmdlCheckFormat ($path) {
    $isTmdl = Test-Path "$path\*.SemanticModel\definition\model.tmdl"
    return $isTmdl
}