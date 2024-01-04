# Script is use for check failed login event 4625 in Windows PC and store the information in FailedLogin.csv file.
# Script also send the email to email which you define in $to variable.
# Use task scheduler to schedule the task on trigger when event 4625 fire.
# Define the SMTP server details and user credentials
# Auth: https://github.com/vskumbhani

$smtpServer = "samtpservernameorip"
$smtpUsername = "email/username"
$smtpPassword = "passwordofemail"
$smtpSecurePassword = ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force
$smtpCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $smtpUsername, $smtpSecurePassword
$from = "fromemail"
$to = "toemail"
# $Port = 465

# Define the hash table to validate the failed reason values
$failedReasons = @{
    "%%2304" = "An Error occured during Logon."
    "%%2305" = "The specified user account has expired."
    "%%2306" = "The NetLogon component is not active."
    "%%2307" = "Account locked out."
    "%%2308" = "The user has not been granted the requested logon type at this machine."
    "%%2309" = "The specified account's password has expired."
    "%%2310" = "Account currently disabled."
    "%%2311" = "Account logon time restriction violation."
    "%%2312" = "User not allowed to logon at this computer."
    "%%2313" = "Unknown user name or bad password."
    "%%2314" = "Domain sid inconsistent."
    "%%2315" = "Smartcard logon is required and was not used."
}

# Get the event details for event ID 4625 in the Security log
$event = Get-WinEvent -FilterHashtable @{LogName='Security';Id=4625} | Sort-Object TimeCreated -Descending | Select-Object -First 1

# Extract the important details from the event
    $Username = $event.Properties[5].Value
    $Ip = $event.Properties[19].Value
    $RemoteHost = $event.Properties[13].Value
    $failedCode = $event.Properties[8].Value
    $datetime = $event.TimeCreated.ToString("yyyy-MM-dd hh:mm:ss tt")
    $Domain = $event.Properties[6].Value
    $regex = "^(::1)$"

    $details = [PSCustomObject]@{
                 DateTime = $datetime
                 Hostname = $env:COMPUTERNAME
                 User = $Username
                 Domain = $Domain
                 RemoteHost = $RemoteHost
                 IP = $Ip
                 Reason = $failedReason
                 }

    if ($Ip -notmatch $regex){

    # Validate the failed reason code and get the corresponding message
    if ($failedReasons.ContainsKey($failedCode)) {
        $failedReason = $failedReasons[$failedCode]
         $body = "Domain: $Domain`r`nUser name: $Username`r`nIP address: $IP`r`nFailed reason: $failedReason`r`nDate & Time: $datetime"
		 
		 $details | Export-Csv -Path "C:\Log\FailedLogin.csv" -NoTypeInformation -Append
		 # Write-Host $body
    Send-MailMessage -From $from -To $to -Subject "Failed Login Alert | User is $Username" -Body $body -SmtpServer $smtpServer -Credential $smtpCredential
    }
    else {
        $failedReason = "Failed to retrieve the reason for the login failure."
        $body = "Domain: $Domain`r`nUser name: $Username`r`nIP address: $IP`r`nFailed reason: $failedReason`r`nDate & Time: $datetime"
     
		$details | Export-Csv -Path "C:\Log\FailedLogin.csv" -NoTypeInformation -Append
        # Write-Host $body
     Send-MailMessage -From $from -To $to -Subject "Failed Login Alert | User is $Username" -Body $body -SmtpServer $smtpServer -Credential $smtpCredential
    }
    }
