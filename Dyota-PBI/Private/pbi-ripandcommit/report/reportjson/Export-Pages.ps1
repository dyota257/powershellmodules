function Export-Pages ($dest, $report) {
    [List[PSCustomObject]] $pages = @()

    $report.sections |
        ForEach-Object {
            # the first page does not have an "ordinal" property, so need to manually add it in so we can sort properly in the sort step
            if ($null -eq $_.ordinal) {
                $_ | Add-Member -NotePropertyName ordinal -NotePropertyValue 0
                $_.ordinal = [int] 0
            }

            # convert the data type to integer - originall text
            try { $_.ordinal = [int] $_.ordinal } catch { }

            $_
        } |
        Sort-Object ordinal |
        ForEach-Object {
            $config = $_.config | ConvertFrom-Json -Depth 20

            $pages.Add(
                [ordered] @{
                    page = $_.displayName
                    # ordinal = $_.ordinal
                    show = ($config.visibility -eq 0) -or ($config.visibility -eq $null)
                }
            )
        }

    $pages | ConvertTo-Json > "$dest\pages.json" -Compress
}
