# Export registry of Environment Variables...

$SystemVariablePath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
$UserVariablePath = "HKCU\Environment"
$ExportDirPath = "C:\Exports"

If(!(Test-Path $ExportDirPath))
{
    mkdir $ExportDirPath
}

Write-Host "Exporting the System Variables..."
$DateTime = Get-Date -Format ddMMyyyy_hhmmsstt

If(!(Test-Path $ExportDirPath\SystemVariable.reg))
{
    Invoke-Command {reg export $SystemVariablePath $ExportDirPath\SystemVariable.reg}
}
Else
{
    Rename-Item -Path $ExportDirPath\SystemVariable.reg -NewName $ExportDirPath\SystemVariable_$DateTime.reg
    Write-Host "Exsiting file renamed..."
    Invoke-Command {reg export $SystemVariablePath $ExportDirPath\SystemVariable.reg}
}

Write-Host "Exporting the User Variables..."

If(!(Test-Path $ExportDirPath\UserVariable.reg))
{
    Invoke-Command {reg export $UserVariablePath $ExportDirPath\UserVariable.reg}
}
Else
{
    Rename-Item -Path $ExportDirPath\UserVariable.reg -NewName $ExportDirPath\UserVariable_$DateTime.reg
    Write-Host "Exsiting file renamed..."
    Invoke-Command {reg export $SystemVariablePath $ExportDirPath\UserVariable.reg}    
}

# Open the exported directory...
Invoke-Item $ExportDirPath