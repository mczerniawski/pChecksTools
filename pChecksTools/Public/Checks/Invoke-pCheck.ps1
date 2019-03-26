function Invoke-pCheck {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, HelpMessage = 'Path to Checks Index File')]
        [System.String]
        $pChecksIndexFilePath,

        [Parameter(Mandatory, HelpMessage = 'Folder with Pester tests')]
        [ValidateScript( {Test-Path -Path $_ -PathType Container})]
        [System.String]
        $pChecksFolderPath,

        [Parameter(Mandatory = $false, HelpMessage = 'test type for Pester')]
        [ValidateSet('Simple', 'Comprehensive')]
        [string[]]
        $TestType = @('Simple', 'Comprehensive'),

        [Parameter(Mandatory = $false, HelpMessage = 'Node to test')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $NodeName,

        [Parameter(Mandatory = $false, HelpMessage = 'hashtable with Configuration',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [hashtable]
        $pCheckParameters,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [switch]
        $WriteToEventLog,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $EventSource,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [int32]
        $EventIDBase,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [switch]
        $WriteToAzureLog,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $CustomerId,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $SharedKey,

        [Parameter(Mandatory = $false, HelpMessage = 'Folder with Pester test results',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateScript( {Test-Path $_ -Type Container -IsValid})]
        [String]
        $OutputFolder,

        [Parameter(Mandatory = $false, HelpMessage = 'FileName for Pester test results',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $FilePrefix,

        [Parameter(Mandatory = $false, HelpMessage = 'Include Date in File Name',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [switch]
        $IncludeDate,

        [Parameter(Mandatory = $false, HelpMessage = 'Show Pester Tests on console',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [String]
        $Show,

        [Parameter(Mandatory = $false, HelpMessage = 'Tag for Pester',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string[]]
        $Tag,

        [Parameter(Mandatory = $false, HelpMessage = 'Target Type to test')]
        [ValidateSet('Nodes', 'General')]
        [string[]]
        $TestTarget = @('Nodes', 'General')
    )
    begin {
        $pesterParams = @{
            PassThru = $true
        }
        if ($PSBoundParameters.ContainsKey('Show')) {
            $pesterParams.Show = $Show
        }
        else {
            $pesterParams.Show = 'None'
        }
    }
    process {
        $pCheckFromIndex = Get-pCheckFromIndex -pChecksIndexFilePath $pChecksIndexFilePath
        if ($pCheckFromIndex) {
            ForEach ($pCheck in $pCheckFromIndex) {
                #region filters checks from INDEX file based in input
                if ($pCheck.TestTarget -in @($TestTarget)) {
                    $getpCheckFilteredSplat = @{
                        pCheckObject = $pCheck
                        TestType     = $TestType
                        TestTarget   = $pCheck.TestTarget
                    }
                    if ($PSBoundParameters.ContainsKey('Tag')) {
                        $getpCheckFilteredSplat.Tag = $Tag
                    }
                    #endregion
                    #region Apply filtered checks from index to actual files on disk
                    $pCheckFiltered = Get-pCheckFiltered @getpCheckFilteredSplat
                    if ($pCheckFiltered) {
                        $getpCheckToProcessSplat = @{
                            pCheckObject      = $pCheckFiltered
                            pChecksFolderPath = $pChecksFolderPath
                        }
                        $checksToProcess = Get-pCheckToProcess @getpCheckToProcessSplat
                        #endregion
                        if ($checksToProcess) {
                            foreach ($file in $checksToProcess) {
                                #region get output file pester parameters

                                $pesterParams.Script = @{
                                    Path       = $file
                                    Parameters = $pCheckParameters
                                }


                                if ($PSBoundParameters.ContainsKey('OutputFolder')) {
                                    $newpCheckFileNameSplat = @{
                                        pCheckFile = $file
                                    }
                                    $newpCheckFileNameSplat.OutputFolder = $OutputFolder
                                    if ($PSBoundParameters.ContainsKey('FilePrefix')) {
                                        $newpCheckFileNameSplat.FilePrefix = $FilePrefix
                                    }
                                    if ($PSBoundParameters.ContainsKey('IncludeDate')) {
                                        $newpCheckFileNameSplat.IncludeDate = $true
                                    }
                                    $pesterParams.OutputFormat = 'NUnitXml'
                                }
                                #endregion
                                if ($pCheckFiltered.TestTarget -eq 'General') {
                                    Write-Verbose "bede robil generala - {$file}"
                                    $newpCheckFileNameSplat.NodeName = 'General'
                                    $pesterParams.OutputFile = New-pCheckFileName @newpCheckFileNameSplat
                                    Write-Verbose -Message "Results for Pester file {$file} will be written to {$($pesterParams.FilePrefix)}"

                                    #region Perform Tests
                                    $invocationStartTime = [DateTime]::UtcNow
                                    $pesterParams
                                    #$pChecksResults = Invoke-Pester @pesterParams
                                    $invocationEndTime = [DateTime]::UtcNow
                                    #endregion
                                    #wygeneruj nazwe pliku,  wykonac test, zapisz

                                }
                                else {
                                    Write-Verbose "bede robil noda - {$file}"
                                    if ($PSBoundParameters.ContainsKey('NodeName')) {
                                        $nodeToProcess = $NodeName
                                    }
                                    else {
                                        $nodeToProcess = 'WszystkieNody'
                                    }
                                    foreach ($node in $nodeToProcess) {
                                        Write-Verbose "Dla Noda $node"
                                        $newpCheckFileNameSplat.NodeName = $node
                                        $pesterParams.OutputFile = New-pCheckFileName @newpCheckFileNameSplat
                                        $pCheckParametersTemporary = $pCheckParameters
                                        $pCheckParametersTemporary.ComputerName = $node
                                        $pesterParams.Script = @{
                                            Path       = $file
                                            Parameters = $pCheckParametersTemporary
                                        }
                                        Write-Verbose -Message "Results for Pester file {$file} will be written to {$($pesterParams.FilePrefix)}"

                                        #region Perform Tests
                                        $invocationStartTime = [DateTime]::UtcNow
                                        $pesterParams
                                        #$pChecksResults = Invoke-Pester @pesterParams
                                        $invocationEndTime = [DateTime]::UtcNow
                                        #endregion
                                    }
                                }

                                #region Where to store results
                                #region EventLog
                                if ($PSBoundParameters.ContainsKey('WriteToEventLog')) {
                                    $pesterEventParams = @{
                                        PesterTestsResults = $pChecksResults
                                        EventSource        = $EventSource
                                        EventIDBase        = $EventIDBase
                                    }
                                    Write-Verbose -Message "Writing test results to Event Log {Application} with Event Source {$EventSource} and EventIDBase {$EventIDBase}"
                                    Write-pChecksToEventLog @pesterEventParams
                                }
                                #endregion

                                #region Azure Log Analytics
                                if ($PSBoundParameters.ContainsKey('WriteToAzureLog')) {
                                    $batchId = [System.Guid]::NewGuid()
                                    $pesterALParams = @{
                                        PesterTestsResults  = $pChecksResults
                                        invocationStartTime = $invocationStartTime
                                        invocationEndTime   = $invocationEndTime
                                        Identifier          = $Identifier
                                        BatchId             = $BatchId
                                        CustomerId          = $CustomerId
                                        SharedKey           = $SharedKey
                                    }
                                    Write-Verbose -Message "Writing test results to Azure Log CustomerID {$CustomerId} with BatchID {$BatchId} and Identifier {$Identifier}"
                                    Write-pChecksToLogAnalytics @pesterALParams
                                }
                                #endregion
                                Write-Verbose -Message "Pester File {$file} Processed type $($pCheckFiltered.TestTarget)"
                            }
                        }
                    }
                }
            }
        }
    }
}