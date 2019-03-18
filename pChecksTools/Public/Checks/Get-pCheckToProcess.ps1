function Get-pCheckToProcess {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, HelpMessage = 'Path to Checks Index File')]
        [System.String]
        $pChecksIndexPath,

        [Parameter(Mandatory, HelpMessage = 'Folder with Pester tests')]
        [ValidateScript( {Test-Path -Path $_ -PathType Container})]
        [System.String[]]
        $pChecksFolderPath,

        [Parameter(Mandatory = $false, HelpMessage = 'test type for Pester')]
        [ValidateSet('Simple', 'Comprehensive')]
        [string[]]
        $TestType = @('Simple', 'Comprehensive'),

        [Parameter(Mandatory = $false, HelpMessage = 'Tag for Pester')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Tag,

        [Parameter(Mandatory=$false,HelpMessage='Node to test')]
        [ValidateSet('Nodes', 'General')]
        [string[]]
        $TestTarget = @('Nodes', 'General')
    )
    process {
        $checksToProces = @()
        #region Filter checks based on Index and Input parametrs
        $pChecksFromIndex = Get-ConfigurationData -ConfigurationPath $pChecksIndexPath -OutputType PSObject | Select-Object -ExpandProperty Checks
        $pChecksTypeFiltered = $pChecksFromIndex | Where-Object {$PSItem.TestType -in $TestType}
        $checksFilteredByTypeAndTag = foreach ($checkByTag in $pChecksTypeFiltered) {
            $testIfInTags = Compare-Object -ReferenceObject $checkByTag.Tag -DifferenceObject @($Tag) -IncludeEqual
            if ($testIfInTags.SideIndicator -eq '==') {
                $checkByTag
            }
        }
        #endregion

        #region Get Checks from pChecksFolderPath based on previous filtering

        $checksToProces += if('Nodes' -in @($TestTarget) ){
            $checksFilteredByTypeAndTag | Where-Object {$PSItem.TestTarget -eq 'Nodes'}
        }
        $checksToProces += if('General' -in @($TestTarget) ){
            $checksFilteredByTypeAndTag | Where-Object {$PSItem.TestTarget -eq 'General'}
        }
        foreach ($check in $checksToProces) {
            Get-ChildItem -Path $pChecksFolderPath -Filter $check.DiagnosticFile -Recurse | Select-Object -ExpandProperty FullName
        }
        #endregion

    }

}