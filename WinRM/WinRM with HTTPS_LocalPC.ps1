# --------------------------Import Certificate ------------------------------#
# Local PC Script. Run this script in PC from which you want to connect the remote pc via WinRM.
# https://github.com/VSKUMBHANI
# Copy the CER file from remote pc and paste it in system from which you want to take access of.

$CerFilePath = "Path\to\Certificatefile.cer"
Import-Certificate -FilePath $CerFilePath -CertStoreLocation Cert:\LocalMachine\root\

# Then, to connect to a remote Windows host using WinRM HTTPS, you must use the -UseSSL argument in the Enter-PSSession and Invoke-Command cmdlets. 
# In the following example, we’ll connect to a remote host from the PowerShell console by its IP address (note that we haven’t added this IP address to TrustedHosts):
# When connecting by an IP address without the SkipCNCheck option, the following error occurs: The SSL certificate contains a common name (CN) that does not match the hostname.

$SessionOption = New-PSSessionOption -SkipCNCheck
Enter-PSSession -Computername ipaddress_of_remote_pc -UseSSL -Credential username -SessionOption $SessionOption