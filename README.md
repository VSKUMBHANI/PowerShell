# PowerShell
PowerShell Commands & Scripts...
# Unblock files in a folder using PowerShell
![image](https://github.com/VSKUMBHANI/PowerShell/assets/102287173/b3c54425-15b6-4fdc-b3c5-bff734aa2119)

Type the following command to unblock all files in a folder by changing the path of the folder to yours.

Get-ChildItem -Path 'C:\Users\Dimitris\Downloads\' | Unblock-File

Or for a shortcut, try the following.

gci 'C:\Users\Dimitris\Downloads \' | Unblock-File

Add the -Recurse switch if you want to unblock all files in the sub-folders.

Get-ChildItem -Path 'C:\Users\Dimitris\Downloads\' -Recurse | Unblock-File

For more visit official docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file?view=powershell-7.3.
