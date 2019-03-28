Function Export-LogAnalytics {
    [cmdletbinding()]
    Param(

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $CustomerID,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $SharedKey,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        [psobject]
        $pChecksResults,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [ValidateNotNullOrEmpty()]
        $LogType,

        [Parameter(Mandatory = $true,
        ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()]
        $TimeStampField
    )
    process {

        $bodyAsJson = ConvertTo-Json $pChecksResults
        $body = [System.Text.Encoding]::UTF8.GetBytes($bodyAsJson)

        $method = 'POST'
        $resource = '/api/logs'
        $rfc1123date = [DateTime]::UtcNow.ToString("r")
        $contentType = 'application/json'

        $getLogAnalyticsSignatureSplat = @{
            CustomerID    = $CustomerID
            SharedKey     = $SharedKey
            Date          = $rfc1123date
            ContentLength = $body.Length
            Method        = $method
            ContentType   = $contentType
            Resource      = $resource
        }
        $signature = Get-LogAnalyticsSignature @getLogAnalyticsSignatureSplat

        $uri = "https://" + $CustomerID + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

        $headers = @{
            "Authorization"        = $signature;
            "Log-Type"             = $LogType;
            "x-ms-date"            = $rfc1123date;
            "time-generated-field" = $TimeStampField;
        }

        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
        $response.StatusCode
    }
}