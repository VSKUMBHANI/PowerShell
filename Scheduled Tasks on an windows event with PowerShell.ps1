# Ref: https://xplantefeve.io/posts/SchdTskOnEvent
# Create Scheduled Tasks on an event with PowerShell

$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger = $class | New-CimInstance -ClientOnly
# $trigger
$trigger.Enabled = $true
$trigger.Subscription = '<QueryList><Query Id="0" Path="Security"><Select Path="Security">*[System[Provider[@Name=''Microsoft-Windows-Security-Auditing''] and EventID=4625]]</Select></Query></QueryList>'

$ActionParameters = @{
    Execute  = 'powershell.exe'
    # Argument = -NoProfile -File C:\scripts\NetworkConnectionCheck.ps1
}

$Action = New-ScheduledTaskAction @ActionParameters
$Principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount
$Settings = New-ScheduledTaskSettingsSet

$RegSchTaskParameters = @{
    TaskName    = 'TaskName'
    Description = 'Run on Event 4625'
    TaskPath    = '\PSTask\'
    Action      = $Action
    Principal   = $Principal
    Settings    = $Settings
    Trigger     = $Trigger
}

Register-ScheduledTask @RegSchTaskParameters
