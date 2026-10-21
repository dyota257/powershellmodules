function Export-RLS ($dest, $model) {
    # if there is RLS, then do
    if ($null -ne $model.model.roles) {
        Write-Host -ForegroundColor Cyan "Ripping RLS... "

        $out = [System.Text.StringBuilder]::new()

        $model.model.roles |
            select name, tablePermissions |
            % {
                $role = $_.name
                [void] $out.AppendLine($role)

                $_.tablePermissions |
                    % {
                        [void] $out.AppendLine("`t$($_.name):`n$( ($_.filterExpression | % { "`t`t$_" }) -join "`n")" )
                    }
            }

        $out.ToString().Trim() > "$dest\rls.txt"
    }

}
