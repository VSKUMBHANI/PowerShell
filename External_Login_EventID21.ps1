# Script is used for check whether login of remote user has made from outside of network or local.
# Use task scheduler to trigger this script on event 21 is generate.
# It will send email once event 21 is trigger and it contain ip then different from define regex in $locallan.
# Auth: https://github.com/vskumbhani

# Define the SMTP server details and user credentials...
	$smtpServer = "smtpserver"
	$smtpUsername = "email/username"
	$smtpPassword = "password"
	$smtpSecurePassword = ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force
	$smtpCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $smtpUsername, $smtpSecurePassword
	$from = "fromemailid"
	$to = "toemailid"

# Define Regex variable for Local IP range. Ref: https://www.analyticsmarket.com/freetools/ipregex/
	$locallan = "^192\.168\.11\.([1-9]|[1-9]\d|1\d\d|2[0-4]\d|25[0-4])$" # LOCAL LAN REGEX

	$logName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational"
	$sourceName = "Microsoft-Windows-TerminalServices-LocalSessionManager"

	$event = Get-WinEvent -LogName $logName -FilterXPath "*[System[(EventID=21) and Provider[@Name='$sourceName']]]" -MaxEvents 1
	$message = $event.Message

# Extract the important details from the event
    $Username = $event.Properties[0].Value
    $SessionID = $event.Properties[1].Value
    $datetime = $event.TimeCreated.ToString("yyyy-MM-dd hh:mm:ss tt")
    $ipAddress = [IPAddress]([regex]::Matches($message, "\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b").Value)

	If ($ipAddress -match $locallan) 
	{
		# Write-Output "IP in range"
	} 
	Else 
	{
		# Write-Output "IP not in range"
		$IPInfo = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$ipAddress" #ip-api have restriction of HTTP request 45 per minute.
		$City = $IPInfo.city
		$State = $IPInfo.regionName
		$Country = $IPInfo.country
		$Zip = $IPInfo.zip
		$ISP = $IPInfo.isp
		
		$body = "<b>User Login Sucessful on Host:</b> $env:COMPUTERNAME<br>`r`n<b>User Name:</b> $Username<br>`r`n<b>Session ID:</b> $SessionID<br>`r`n<b>IP Address:</b> $ipAddress<br>`r`n<b>City:</b> $City<br>`r`n<b>State:</b> $State<br>`r`n<b>Country:</b> $Country<br>`r`n<b>ISP:</b> $ISP<br>`r`n<b>Date & Time:</b> $datetime<br>"
		Send-MailMessage -From $from -To $to -Subject "User $Username Loggedin into the $env:COMPUTERNAME with External IP $ipAddress" -Body $body -BodyAsHtml -SmtpServer $smtpServer -Credential $smtpCredential -Port 465 -UseSsl
