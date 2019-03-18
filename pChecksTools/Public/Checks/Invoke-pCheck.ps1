function Invoke-pCheck {

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, HelpMessage = 'Path to Checks Index File')]
        [System.String]
        $pChecksIndexPath,

        [Parameter(Mandatory, HelpMessage = 'Folder with Pester tests')]
        [ValidateScript( {Test-Path -Path $_ -PathType Container})]
        [System.String[]]
        $pChecksFolderPath,

        [Parameter(Mandatory = $false, HelpMessage = 'test type for Pester')]
        [ValidateSet('Simple', 'Comprehensive')]
        [string[]]
        $TestType = @('Simple', 'Comprehensive'),

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
        $pCheckFromIndex = Get-pCheckFromIndex -pChecksIndexPath $pChecksIndexPath
        if ($pCheckFromIndex) {
            ForEach ($pCheck in $pCheckFromIndex) {
                if ($pCheck.TestTarget -in @($TestTarget)) {
                    $getpCheckFilteredSplat = @{
                        pCheckObject = $pCheck
                        TestType = $TestType
                        TestTarget = $pCheck.TestTarget
                    }
                    if($PSBoundParameters.ContainsKey('Tag')) {
                        $getpCheckFilteredSplat.Tag = $Tag
                    }
                    $pCheckFiltered = Get-pCheckFiltered @getpCheckFilteredSplat
                    if ($pCheckFiltered) {
                        $getpCheckToProcessSplat = @{
                            pCheckObject = $pCheckFiltered
                            pChecksFolderPath = $pChecksFolderPath
                        }
                        $checksToProcess = Get-pCheckToProcess @getpCheckToProcessSplat
                        if ($checksToProcess) {
                            if($pCheckFiltered.TestTarget -eq 'General') {
                                Write-Verbose 'bede robil generala'
                                Invoke-pCheckFinal #reszta parametrow do Generala
<#
                                foreach ($file in $checksToProcess) {

                                    $pesterParams.Script = @{
                                        Path       = $file
                                        Parameters = $pCheckParameters
                                    }
                                    #wygeneruj nazwe pliku,  wykonac test, zapisz
                                    Write-Verbose -Message "Pester File {$file} Processed type $($pCheckFiltered.TestTarget)"
                                }
                                #>
                            }
                            else {
                                Write-Verbose 'bede robil noda'
                                Invoke-pCheckFinal #reszta parametrow per node (jak sprawdzic ktore nody faktycznie sa nodami?)
                                foreach ($file in $checksToProcess) {
                                    $pesterParams.Script = @{
                                        Path       = $file
                                        Parameters = $pCheckParameters
                                    }
                                    #wygeneruj nazwe pliku,  wykonac test, zapisz
                                    Write-Verbose -Message "Pester File {$file} Processed type $($pCheckFiltered.TestTarget)"
                                }
                            }

                        }
                    }
                }
            }
        }
    }
}