function Get-pChecksTeamingConfiguration {
    [CmdletBinding()]
    [OutputType([ordered])]
    param (

        [Parameter(Mandatory,
            ParameterSetName = 'ComputerName')]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ComputerName,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ComputerName')]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    process {
        #region Variables set
        if ($PSBoundParameters.ContainsKey('ComputerName')) {
            $sessionParams = @{
                ComputerName = $ComputerName
                SessionName  = "pChecks-$ComputerName"
            }

            if ($PSBoundParameters.ContainsKey('Credential')) {
                $sessionParams.Credential = $Credential
            }
            $pChecksPSSession = New-PSSession @SessionParams
        }

        #endregion
        $hostTeams = @()
        $hostTeams = Invoke-Command $pChecksPSSession -ScriptBlock {
            Get-NetLbfoTeam | ForEach-Object {
                @{
                    Name                   = $PSItem.Name
                    TeamingMode            = $PSitem.TeamingMode.ToString()
                    LoadBalancingAlgorithm = $PSitem.LoadBalancingAlgorithm.ToString()
                    Members                = @($PSItem.Members)
                }
            }
        }
        #to Avoid issues with PSComputerName and RunspaceId added to each object from invoke-command - I'm reassigning each hashtable
        foreach ($hostTeam in $hostTeams) {
            [ordered]@{
                Name                   = $hostTeam.Name
                TeamingMode            = $hostTeam.TeamingMode
                LoadBalancingAlgorithm = $hostTeam.LoadBalancingAlgorithm
                Members                = @($hostTeam.Members)
            }
        }


        Remove-PSSession -Name $pChecksPSSession.Name -ErrorAction SilentlyContinue

    }
}