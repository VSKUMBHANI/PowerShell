
<# Import-Module -Name Vmware.PowerCLI
    # To ignore CEIP participation.
    # Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
    # To ignore certificate error
    # Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#>

$Server = 'vmware serverip'
$User = 'root'
$Password = 'pass'

# Save copy logs.
$Logpath = $PSScriptRoot
$LogFile = $Logpath+'\'+'startvms.log'

#Function to Create a Log File
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $Message,
        [Parameter(Mandatory = $false)] [ValidateSet("INFO","WARNING","ERROR")] [string] $Level = "INFO"
    )
    $Timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "$timestamp [$Level] - $Message"
}

Start-Sleep -Seconds 10
Write-Log -level INFO -message "------ PowerOn VM Script started ------"

#Start-Transcript $Logfile
Connect-VIServer -Server $Server -User $User -Password $Password
$Vms = Get-VM

try{
foreach($vm in $Vms)
    {
        if($vm.PowerState -ne 'PoweredON')
        {
                Write-Log -Level INFO -Message "Starting Guest VM: $($vm.Name)"
                Start-VM -VM $vm.Name -Confirm:$false
                Start-Sleep -Seconds 10
         }#if
         else
         {
                Write-Log -Level INFO -Message "$($vm.Name) is already powered on...." 
         }#else
    }#foreach
}#try
Catch
{
    Write-Log -Level ERROR -Message "Error....!!!!"
}#catch

Disconnect-VIServer -Server $Server -Confirm:$false
Write-Log -level INFO -message "------ PowerOn VM Script ended ------"
#Stop-Transcript
