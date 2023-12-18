# Import registry of Environment Variables...
# https://github.com/VSKUMBHANI

$ImportDirPath = "C:\Imports"

Write-Host "Importing the System Variables..."
Invoke-Command {reg import $ImportDirPath\SystemVariable.reg}

Write-Host "Importing the User Variables..."
Invoke-Command {reg import $ImportDirPath\UserVariable.reg}

# Open Environment Variables...
rundll32 sysdm.cpl,EditEnvironmentVariables
