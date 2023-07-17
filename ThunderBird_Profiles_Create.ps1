# Script is used to create the profiles.ini file for Thunderbird with a custom path.
# profiles.ini file default path is %appdata%\Thunderbird\
# To use this file, run this script and install Thunderbird.exe (do not start the program).
# After installation run the thunderbird with thunderbird -p to open the Profile Manager.
# In Profile Manager select the default and press the ok button.

$user = $env:USERNAME
$DirThunderbirdPath = "C:\Users\$user\AppData\Roaming\Thunderbird"
$FilePorfileIni = "C:\Users\$user\AppData\Roaming\Thunderbird\profiles.ini"
$NewProfilesPath = "D:\Mail\$user\Thunderbird"
If (Get-Item -Path $NewProfilesPath)
{
    Write-Host "Folder Thunderbird Exist"
}
Else
{
    Write-Host "Folder Thunderbird not Exist"
    New-Item -ItemType Directory -Path $NewProfilesPath
}

$newProfile = @"
[Profile1]
Name=default
IsRelative=0
Path=$NewProfilesPath
Default=1

[Profile0]
Name=default-release
IsRelative=0
Path=$NewProfilesPath
"@

If (Get-Item -Path $DirThunderbirdPath)
{
    Write-Host "Folder Exist"
    If (Get-Item -Path $FilePorfileIni)
    {
        Write-Host "File Exist"
        If (Test-Path $FilePorfileIni) 
        {
            $profiles = Get-Content $FilePorfileIni
            for ($i = 0; $i -lt $profiles.Length; $i++) 
            {
                If ($profiles[$i] -match "^Path=") 
                {
                    $profiles[$i] = "Path=$NewProfilesPath"
                }
            }
            Set-Content $FilePorfileIni $profiles -Encoding ASCII
            Write-Host "Successfully updated all profile paths to $NewProfilesPath."
        }
    }
    Else
    {
        Write-Host "File not Exist"
        New-Item -ItemType File -Path $FilePorfileIni
        (Get-Content $FilePorfileIni) +$newProfile | Set-Content $FilePorfileIni
    }
}
Else
{
    Write-Host "Folder Not Exist"
    New-Item -ItemType Directory -Path $DirThunderbirdPath
    New-Item -ItemType File -Path $FilePorfileIni
    (Get-Content $FilePorfileIni) +$newProfile | Set-Content $FilePorfileIni
}
