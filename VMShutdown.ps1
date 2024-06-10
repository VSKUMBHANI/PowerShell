<# Import-Module -Name Vmware.PowerCLI
    # To ignore CEIP participation.
    # Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false
    # To ignore certificate error
    # Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
#>

$Server = 'vmip'
$User = 'root'
$Password = 'pass'

# Save copy logs.
$Logpath = $PSScriptRoot
$Logfile = $Logpath+'/'+'vmshutdown1.log'

#Function to Create a Log File
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)] [ValidateSet("INFO","WARNING","ERROR")] [string] $level = "INFO"
    )
    $Timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    Add-Content -Path $LogFile -Value "$timestamp [$level] - $message"
}

Write-Log -level INFO -message "------ Shutdown VM Script started ------"

Connect-VIServer -Server $Server -User $User -Password $Password
$Vms = Get-VM

try{
foreach($vm in $Vms)
    {
    $toolversion = $vm.Guest.ToolsVersion
    $toolversion
        if($vm.PowerState -eq 'PoweredON')
        {
            if(!$toolversion)
            {
                Write-Log -level INFO -message "$($vm.Name) is PoweredON and not having installed guest tool."
                Write-Log -level INFO -message "===>Shuting down $($vm.Name) forcefull<==="
                Stop-VM -VM $vm.Name -Confirm:$false
                Start-Sleep -Seconds 10
            }#if
            else
            {
                Write-Log -level INFO -message "$($vm.Name) is PoweredON and having guest tool installed version $($toolversion)"
                Write-Log -level INFO -message "===>Shuting down $($vm.Name) gracefull<==="
                Shutdown-VMGuest -VM $vm.Name -Confirm:$false
                Start-Sleep -Seconds 10
            }#else
        }#if
        else
        {
            Write-Log -level INFO -message "$($vm.Name) is poweredoff."
        }#else
    }#foreach
}#try
Catch
{
    Write-Log -level ERROR -message "Script not run...Error...!!!"
}#catch

Disconnect-VIServer -Server $Server -Confirm:$false
Write-Log -level INFO -message "------ Shutdown VM Script end ------"
