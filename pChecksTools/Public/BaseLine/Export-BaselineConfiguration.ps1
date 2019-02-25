function Export-BaselineConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashTable]
        [ValidateNotNullOrEmpty()]
        $BaselineConfiguration,

        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateScript( {Test-Path -Path (Split-Path -Path $PSItem -Parent) -PathType Container})]
        $BaselineConfigurationFolder
    )
    process {
        #region path variable initialization
        New-BaselineFolderStructure $BaselineConfigurationFolder
        #endregion
        #region Generate files
        #region non-node configuration
        $nonNodefileName = ('{0}.Configuration.json' -f $BaselineConfiguration.NonNodeData.Name)
        $forestConfigFile = [System.IO.Path]::Combine("$BaselineConfigurationFolder", "NonNodeData", "$nonNodefileName")
        $BaselineConfiguration.NonNodeData | ConvertTo-Json -Depth 99 | Out-File -FilePath $forestConfigFile
        #endregion
        #region node-configuration
        foreach ($nodeConfig in $BaselineConfiguration.AllNodes) {
            $nodeFileName = ('{0}.Configuration.json' -f $nodeConfig.ComputerName)
            $nodeFile = [System.IO.Path]::Combine("$BaselineConfigurationFolder", "AllNodes", "$nodeFileName")
            $nodeConfig | ConvertTo-Json -Depth 99 | Out-File -FilePath $nodeFile
        }
        #endregion

    }
}