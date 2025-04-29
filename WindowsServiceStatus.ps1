# Define the name of the service.

$name = "Agent"
# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrative privileges. Please run it as an administrator."
    exit
}

# Check if the service exists

$service = Get-Service -Name $name -ErrorAction SilentlyContinue
if (-not $service) 
{
    Write-Host "Service '$name' does not exist."
    exit
}
Write-Host "Current status of '$name' service: $($service.Status)"
if ($service.Status -ne 'Running') 
{
    try {
        Start-Service -Name $name -ErrorAction Stop
        Write-Host "'$name' service started."
    }
    catch
    {
        Write-Host "Failed to start '$name' service. Error: $($_.Exception.Message)"
    }
}
else
{
    Write-Host "'$name' service is already running."
}
