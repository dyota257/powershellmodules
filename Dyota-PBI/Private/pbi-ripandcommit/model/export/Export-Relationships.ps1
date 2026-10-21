using namespace System.Text
using namespace System.Collections.Generic

function Export-Relationships ($dest, $model) {
    # all relationships are defined in "relationships"
    $relationships = $model.model.relationships

    # tables contain further definition for columns - we need data type for the dbml file format
    $tables = $model.model.tables
        # ForEach-Object {
        #     $_.columns = $_.columns | Select-Object name, dataType
        #     $_ | Select-Object name, columns
        # }

    # set up stringbuilder for final output to file
    $sb = [StringBuilder]::new()

    # set up a temporary collection of tables and columns to iterate over later
    # this is to make sure that only the columns involved in relationships are picked up, and no more
    # and also to make sure there are no duplicates in columns
    [List[PSCustomObject]] $tablesCollection = @()

    # fill in $tablesCollection
    $relationships |
        ForEach-Object {
            $tablesCollection.Add( @{table = $_.fromTable.Name; column = $_.fromColumn.Name; } )
            $tablesCollection.Add( @{table = $_.toTable.Name; column = $_.toColumn.Name; } )
        }

    # if table or column names contain spaces, the need to be double-quoted
    function quote ($text) {
        $condition = $text.Contains(" ") -or $text.Contains("-")

        if ($condition) { return "`"$text`"" } else { return $text }
    }

    # process over $tablesCollection
    # this block will write out all of the table definitions for dbml

    $tablesCollection |
        Group-Object table |
        ForEach-Object {
            $columns = [StringBuilder]::new()

            [String] $tableName = $_.Name

            $_.Group |
                Select-Object -Unique column |
                ForEach-Object {
                    $columnName = $_.column
                    $dataType = ( ($tables | Where-Object { $_.name -eq $tableName }).columns | Where-Object { $_.name -eq $columnName } ).dataType

                    [void] $columns.AppendLine("`t$(quote $columnName) $dataType")
                }
                $out = @"
Table $(quote $tableName) {
$($columns.ToString())
}
"@
                [void] $sb.AppendLine($out)
            }

    # this block will write out all of the relationship definitions for dbml, at the bottom of the file
    # note that it is assumed that all relationships are in the > direction. I don't know where the relationship type property lives in model.bim
    # note that active/inactive relationship states are not captured here
    $relationships |
        Sort-Object fromTable, fromColumn |
        ForEach-Object {
            [void] $sb.AppendLine( "Ref: $(quote $_.fromTable.Name).$(quote $_.fromColumn.Name) > $(quote $_.toTable.Name).$(quote $_.toColumn.Name)" )
        }

    # write to file
    $sb.ToString() > "$dest\relationships.dbml"
}
