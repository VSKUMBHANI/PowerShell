$servicesNames = 'service_main',
    'application1',
    'application2'

Write-host "Stoping Services"
Write-host "--------------------------"

foreach ($srv in $servicesNames) {
    Write-host "Stopping: " + $srv
    $SrvPID = (get-wmiobject win32_service | where { $_.name -eq $srv}).processID
    Write-host "PID: " + $SrvPID

    # If the process is stuck add -Force
    Stop-Process $SrvPID -Force
    Write-host "PDI " + $SrvPID + " stopped"
}
Write-host "Starting Services........"

foreach ($srv in $servicesNames) {
    Write-host "Starting: " + $srv
    Start-Service $srv
}
