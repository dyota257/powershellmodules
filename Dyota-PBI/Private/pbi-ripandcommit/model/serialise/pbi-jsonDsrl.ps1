

function pbi-jsonDsrl ($modelPath) {
    # a model.bim file is actually a [Database] object, with a [Model] object inside it
    # this is why we use the DeserializeDatabase method

    $json = Get-Content $modelpath -Raw

    $tabularDatabase = [Microsoft.AnalysisServices.Tabular.JsonSerializer]::DeserializeDatabase($json)

    return $tabularDatabase

}