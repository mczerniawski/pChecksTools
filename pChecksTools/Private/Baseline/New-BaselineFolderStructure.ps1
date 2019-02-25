function New-BaselineFolderStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateScript( {Test-Path -Path (Split-Path -Path $PSItem -Parent) -PathType Container})]
        $BaselineConfigurationFolder
    )

    if (-not (Test-Path $BaselineConfigurationFolder)) {
        [void](New-Item -Path $BaselineConfigurationFolder -ItemType Directory)
    }
    $nonNodeDataPath = (Join-Path -Path $BaselineConfigurationFolder -childPath 'NonNodeData')
    $allNodesDataPath = (Join-Path -Path $BaselineConfigurationFolder -childPath 'AllNodes')

    if (-not (Test-Path $nonNodeDataPath)) {
        [void](New-Item -Path $nonNodeDataPath -ItemType Directory)
    }
    if (-not (Test-Path $allNodesDataPath)) {
        [void](New-Item -Path $allNodesDataPath -ItemType Directory)
    }
}