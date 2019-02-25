function Import-BaselineConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateScript( {Test-Path -Path $PSItem -PathType Container})]
        $BaselineConfigurationFolder
    )
    process {

        $BaselineConfiguration = @{
            AllNodes    = @()
            NonNodeData = @()
        }

        #region Get Service Configuration Data (i.e. your DHCP global configuration)
        $BaselineConfiguration.NonNodeData = Get-ConfigurationData -ConfigurationPath (Join-Path -Path $BaselineConfigurationFolder -ChildPath 'NonNodeData') -OutputType HashTable
        #endregion

        #region Get Service Nodes Configuration Data (i.e. your DHCP servers specific configuration)
        $BaselineConfiguration.AllNodes += Get-ConfigurationData -ConfigurationPath (Join-Path -Path $BaselineConfigurationFolder -ChildPath 'AllNodes') -OutputType HashTable
        #endregion

        $BaselineConfiguration

    }
}