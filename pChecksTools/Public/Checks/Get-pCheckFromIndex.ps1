function Get-pCheckFromIndex {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, HelpMessage = 'Path to Checks Index File')]
        [System.String]
        $pChecksIndexFilePath
    )
    process {
        Get-ConfigurationData -ConfigurationPath $pChecksIndexFilePath -OutputType PSObject | Select-Object -ExpandProperty Checks
    }
}