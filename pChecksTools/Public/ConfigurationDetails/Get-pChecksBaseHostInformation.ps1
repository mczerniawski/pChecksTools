function Get-pChecksBaseHostInformation {
    [CmdletBinding()]
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
                SessionName  = "Baseline-$ComputerName"
            }
            if ($PSBoundParameters.ContainsKey('Credential')) {
                $sessionParams.Credential = $Credential
            }
            $BaselinePSSession = New-PSSession @SessionParams
        }

        #endregion
        $hostProperties = Invoke-Command -session $BaselinePSSession -scriptBlock {
            @{
                ComputerName = $ENV:ComputerName
                Domain       = $env:USERDNSDOMAIN
            }
        }
        $cluster = Invoke-Command -session $BaselinePSSession -scriptBlock {
            if (Get-Command Get-Cluster -ErrorAction SilentlyContinue) {
                Get-Cluster -ErrorAction SilentlyContinue
            }
            else {
                $null
            }
        }
        $result = [ordered]@{
            ComputerName = $hostProperties.ComputerName
            Domain       = $hostProperties.Domain
        }
        if ($cluster) {
            $result.Cluster = $cluster.Name
        }
        $result
        Remove-PSSession -Name $BaselinePSSession.Name -ErrorAction SilentlyContinue
    }
}