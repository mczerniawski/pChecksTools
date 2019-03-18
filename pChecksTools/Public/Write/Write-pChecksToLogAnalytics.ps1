
Function Write-pChecksToLogAnalytics {
    #TODO
    [cmdletbinding()]
    Param(

        [Parameter(Mandatory=$true)]
        $BatchId,

        [Parameter(Mandatory=$true)]
        $CustomerId,

        [Parameter(Mandatory=$true)]
        $SharedKey,

        $PesterTestsResults,
        $invocationStartTime,
        $invocationEndTime,
        $Identifier

    )

    if($PesterTestsResults.TestResult.Count -gt 0) {
        $pesterResults = @()
        foreach($testResult in $PesterTestsResults.TestResult) {
            $pesterResults += [PSCustomObject]@{
                BatchId = $batchId
                InvocationId = [System.Guid]::NewGuid()
                InvocationStartTime = $invocationStartTime
                InvocationEndTime = $invocationEndTime
                HostComputer = $env:computername
                Target = $config.ServerInstance
                TimeTaken = $testResult.Time.TotalMilliseconds
                Passed = $testResult.Passed
                Describe = $testResult.Describe
                Context = $testResult.Context
                Name = $testResult.Name
                FailureMessage = $testResult.FailureMessage
                Result = $testResult.Result
                Identifier = $Identifier
            }
        }

        $exportArguments = @{
            CustomerId = $CustomerId
            SharedKey = $SharedKey
            LogType = "PesterResult"
            TimeStampField = "InvocationStartTime"
        }

        Write-Verbose "Exporting $($pesterResults.Count) results"
        Export-LogAnalytics @exportArguments $pesterResults
    } else {
        Write-Verbose "No test results for $($config.ServerInstance)"
    }
}