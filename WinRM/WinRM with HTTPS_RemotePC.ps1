# Configure Windows Remote Management.
# Remote PC Script. Run this script on which want to configure WinRM.
# Script is for set HTTPS WinRM connection using self-sign certificate.
# https://github.com/VSKUMBHANI
# Check the network profile if it is public then change the network type to Private. Uncomment below command to set the Private profile.
# Set-NetConnectionProfile -NetworkCategory Private

# If you want to skip check network profile run below command.
# Enable-PSRemoting –SkipNetworkProfileCheck

$hostName = $env:COMPUTERNAME # Get Hostname.
$hostIP=(Get-NetAdapter| Get-NetIPAddress).IPv4Address|Out-String # Get Current IP Address.

# Generate new self-sign certificate. It will be used for Authentication of system while connect it using Enter-PSSession from remote computer.
$srvCert = New-SelfSignedCertificate -DnsName $hostName,$hostIP -CertStoreLocation Cert:\LocalMachine\My -NotAfter (Get-Date).AddYears(20)
$srvCert

# By default, two listeners on different ports are created for PowerShell Remoting in Windows [HTTP on Port 5985][HTTPS on Port 5986]

# You can get a list of active WSMan listeners as shown below.
Get-ChildItem wsman:\localhost\Listener

# Remove default HTTP and HTTPS listeners:
Get-ChildItem wsman:\localhost\Listener\ | Where-Object -Property Keys -like 'Transport=HTTP*' | Remove-Item -Recurse

# Create a new HTTPS listener and bind your certificate to it:
New-Item -Path WSMan:\localhost\Listener\ -Transport HTTPS -Address * -CertificateThumbPrint $srvCert.Thumbprint -Force

# Create a Windows Firewall rule that allows WinRM HTTPS traffic or make sure that it is active:
New-NetFirewallRule -Displayname 'Powershell remoting WinRM HTTPS-In' -Name 'Powershell remoting WinRM HTTPS-In' -Profile Any -LocalPort 5986 -Protocol TCP

#Restart the WinRM service:
Restart-Service WinRM

# You can check which certificate thumbprint a WinRM HTTPS listener is bound to using this command.
WinRM e winrm/config/listener

# The remote host is configured. Now you have to export the SSL certificate to a CER file.
$Folder = $MyInvocation.MyCommand.Path | Split-Path -Parent

Export-Certificate -Cert $srvCert -FilePath $Folder\WinRM_$hostName.cer
Invoke-Item $Folder

# Keep in mind that WinRM server and client configurations don’t allow unencrypted connections (by default).
# WinRM dosn't allow Unencrypted connections
# If necessary, you can disable unencrypted connections as follows:

#winrm set winrm/config/service '@{AllowUnencrypted="false"}'
#winrm set winrm/config/client '@{AllowUnencrypted="false"}'

dir WSMan:\localhost\Service | ? Name -eq AllowUnencrypted
dir WSMan:\localhost\Client | ? Name -eq AllowUnencrypted

