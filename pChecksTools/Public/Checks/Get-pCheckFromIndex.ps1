function Get-pCheckFromIndex {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, HelpMessage = 'Path to Checks Index File')]
        [System.String]
        $pChecksIndexPath
    )
    process {
        Get-ConfigurationData -ConfigurationPath $pChecksIndexPath -OutputType PSObject | Select-Object -ExpandProperty Checks
    }
}