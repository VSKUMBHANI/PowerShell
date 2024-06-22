# Script will clean the cache and cookies of firefox browser.
# https://github.com/VSKUMBHANI/PowerShell
# Tested in Firefox v127.0.1

$FireFox = {
    # Create a User Variable for the ScriptBlock to use #
    $user = $env:USERNAME
    
    Write-Host $user
    
    # Remove Cookies from FireFox #
    if (Test-Path C:\Users\$user\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\cookies.sqlite) {
        Remove-Item -path C:\Users\$user\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\cookies.sqlite -ErrorAction SilentlyContinue
        Write-Host "FireFox Cookies have been found and cleaned."
    }
    else {
        Write-Host "FireFox Cookies not found."
    }

    # Remove Cache from Firefox #
    if (Test-Path -path C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default-release\cache2) {
        Remove-Item -path C:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default-release\cache2 -recurse -ErrorAction SilentlyContinue
        Write-Host "Firefox Cache has been found and cleaned."
    }
    else {
        # If no cookies found print a msg #
        Write-Host "FireFox Cache not found."
    }
}


invoke-command -scriptblock $Firefox
