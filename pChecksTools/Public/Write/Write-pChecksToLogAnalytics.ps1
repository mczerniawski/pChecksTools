
Function Write-pChecksToLogAnalytics {
    #TODO
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $BatchId,

        [Parameter(Mandatory = $false, HelpMessage = 'Name for cheks to store in Azure Log ANalytics',
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $Identifier,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $CustomerId,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $SharedKey,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $PesterTestsResults,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [DateTime]
        $invocationStartTime,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [DateTime]
        $invocationEndTime

    )

    if ($PesterTestsResults.TestResult.Count -gt 0) {
        $pChecksResults = @()
        foreach ($testResult in $PesterTestsResults.TestResult) {
            $pChecksResults += [PSCustomObject]@{
                BatchId             = $batchId
                InvocationId        = [System.Guid]::NewGuid()
                InvocationStartTime = $invocationStartTime
                InvocationEndTime   = $invocationEndTime
                HostComputer        = $env:computername
                Target              = $config.ServerInstance
                TimeTaken           = $testResult.Time.TotalMilliseconds
                Passed              = $testResult.Passed
                Describe            = $testResult.Describe
                Context             = $testResult.Context
                Name                = $testResult.Name
                FailureMessage      = $testResult.FailureMessage
                Result              = $testResult.Result
                Identifier          = $Identifier
            }
        }

        $exportArguments = @{
            CustomerId     = $CustomerId
            SharedKey      = $SharedKey
            LogType        = "PesterResult"
            TimeStampField = "InvocationStartTime"
        }

        Write-Verbose "Exporting $($pChecksResults.Count) results"
        Export-LogAnalytics @exportArguments $pChecksResults
    }
    else {
        Write-Verbose "No test results"
    }
}