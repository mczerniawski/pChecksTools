function Invoke-pCheckFinal {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $True, HelpMessage = 'File with tests',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateScript( {Test-Path -Path $_ -PathType Leaf})]
        [string[]]
        $pCheckFile,

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
        [ValidateScript( {Test-Path $_ -Type Leaf -IsValid})]
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
        $Tag
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
        if ($PSBoundParameters.ContainsKey('Tag')) {
            $pesterParams.Tag = $Tag
        }
    }
    process {
        ForEach ($file in $pCheckFile) {
            $pesterParams.Script = @{
                Path       = $file
                Parameters = $pCheckParameters
            }
            #region Get Final Output file Name
            if ($PSBoundParameters.ContainsKey('OutputFolder')) {
                if (-not (Test-Path -Path $OutputFolder -PathType Container -ErrorAction SilentlyContinue)) {
                    [void](New-Item -Path $OutputFolder -ItemType Directory)
                }
                if ($PSBoundParameters.ContainsKey('FilePrefix')) {
                    $fileNameTemp = Join-Path -Path $OutputFolder -ChildPath $FilePrefix
                    if ($PSBoundParameters.ContainsKey('IncludeDate')) {
                        $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
                        $fileName = '{0}_{1).xml' -f $fileNameTemp, $timestamp
                    }
                    else {
                        $fileName = '{0}.xml' -f $fileNamePart
                    }
                }
                else {
                    $timestamp = Get-Date -Format 'yyyyMMdd_HHmm'
                    $fileNameTemp = (split-Path $file -Leaf).replace('.ps1', '')
                    $childPath = "{0}_{1}.xml" -f $fileNameTemp, $timestamp
                    $fileName = Join-Path -Path $OutputFolder -ChildPath $childPath
                }
                $pesterParams.FilePrefix = $fileName
                $pesterParams.OutputFormat = 'NUnitXml'
                Write-Verbose -Message "Results for Pester file {$file} will be written to {$($pesterParams.FilePrefix)}"
            }
            #endregion
            #region Perform Tests
            $invocationStartTime = [DateTime]::UtcNow
            $pChecksResults = Invoke-Pester @pesterParams
            $invocationEndTime = [DateTime]::UtcNow
            #endregion
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
            #endrgion
            #endregion
            Write-Verbose -Message "Pester File {$file} Processed."
        }
    }
}