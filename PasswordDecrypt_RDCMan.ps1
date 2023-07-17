<# 
The script is used for retrieving the password from RDCMan.exe.
The script is only working within the profile from which the original .rdg file was generated. 
Because The string is encoded with the local user profile that is used to set the password in the RDG file. 
Therefore the string cannot be decrypted from another user account than yours.
1. Rename the RDP.rdg file to RDP.xml in the original folder or you may copy it to a different location.
2. Rename the RDCMan.exe to RDCMan.dll in the C:\Temp folder in the original folder or you may copy it to a different location.
#>
Import-Module 'C:\Users\User\Documents\Mesh\RDCMan.dll'
$EncryptionSettings = New-Object -TypeName RdcMan.EncryptionSettings
$xml = [xml](Get-Content "C:\Users\User\Documents\Mesh\RDP.xml") # Path to RDP.xml file.
$passwords = Select-Xml -Xml $xml -XPath "//password"
$usernames = Select-Xml -Xml $xml -XPath "//userName"
foreach ($password in $passwords)
{
    $elementValue = $password.Node.InnerXml
    $username = $usernames[$passwords.IndexOf($password)].Node.InnerXml
    $Pass = [RdcMan.Encryption]::DecryptString($password, $EncryptionSettings)
    Write-Host "UserName is: $username and Password is: $Pass" 
}