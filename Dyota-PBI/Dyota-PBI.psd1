# Generated with Claude Code (claude-sonnet-4-5-20250929) on 2025-10-23

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Dyota-PBI.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'

    # Author of this module
    Author = 'Dyota Tanuwibawa'

    # Company or vendor of this module
    CompanyName = ''

    # Copyright statement for this module
    Copyright = '(c) 2025. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Personal PowerShell module for working with Power BI project files (.pbip). Provides functions for searching, ripping code, managing themes, and more.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'pbi-search'
        'pbi-rip'
        'pbi-ripandcommit'
        'pbi-reconstruct'
        'pbi-resize'
        'pbi-makeTheme'
        'pbi-files'
        'pbi-propagate'
        'pbi-gitCheckout'
        'pbi-backup'
        'pbi-setComponents'
        'pbip'
        'pbi-publish'
        'pbi-setup'
        'pbi-watch'
        'watch'
        'pbi-tidy'
        'pbi-GetFiles'
        'pbi-ripCode'
        'pbi-docs'
        'pbi-rename'
        'pbip-init'
        'pbip-renamePages'
        'pbi-test'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('PowerBI', 'PBIP', 'DAX', 'PowerQuery', 'DataModeling')

            # Release notes of this module
            ReleaseNotes = 'Refactored module structure with separate files for each function.'
        }
    }
}
