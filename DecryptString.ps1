# Script is used for decrypt the string from ini file.
# https://github.com/VSKUMBHANI/PowerShell

$iniFilePath = 'C:\path\to\file.ini'
$oriString = Import-Clixml -Path $iniFilePath | ConvertFrom-SecureString
$string = $oriString | ConvertTo-SecureString
$string
$Marshal = [System.Runtime.InteropServices.Marshal]
$Marshal
$Bstr = $Marshal::SecureStringToBSTR($string)
$Bstr
$pwd = $Marshal::PtrToStringAuto($Bstr)
$pwd
