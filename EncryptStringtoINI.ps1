# Script is used for encrypt the string and save it in .INI file in script location.
# https://github.com/VSKUMBHANI/PowerShell

# Prompt for the value of the string
$string = Read-Host -Prompt "Enter the string to encrypt"

# Encrypt the string
$secureString = $string | ConvertTo-SecureString -AsPlainText -Force

# Convert the encrypted string to a protected string
$protectedString = $secureString | ConvertFrom-SecureString

# Save the encrypted value in the INI file
$iniFilePath = $PSScriptRoot+'\'+'file.ini'
Set-Content -Path $iniFilePath -Value "variable=$protectedString"

# Retrieve and decrypt the string from the INI file
$encryptedString = Get-Content -Path $iniFilePath | ConvertFrom-StringData

$secureString = ConvertTo-SecureString $encryptedString.variable

# Use the decrypted string
$plainString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))
Write-Host "Decrypted string: $plainString"
