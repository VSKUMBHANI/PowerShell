# Script is used for check the connection is established on specific port.
# $SourceIP = “127.0.0.1”
$TargetPort =”5650”
# $log = "C:\PS1\portlog.txt"
$EstablishedConnections = Get-NetTCPConnection -State Established
Foreach ($Connection in $EstablishedConnections)
{
	#Write-Host $Connection.LocalPort
	If (($Connection.LocalPort -eq $TargetPort))
	{
		Write-Host $Connection.LocalPort

		Add-Type -AssemblyName System.Windows.Forms
		$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
		$path = (Get-Process -id $pid).Path
		$balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
		$balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
		$balmsg.BalloonTipText = "From $($Connection.RemoteAddress)"
		$balmsg.BalloonTipTitle = "Connection Established"
		$balmsg.Visible = $true
		$balmsg.ShowBalloonTip(10000)
		# (Get-Date).ToString() + ' ' + $Connection.RemoteAddress + ' an RDP connection is established ' >> $log
	}
}