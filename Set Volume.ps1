# https://github.com/VSKUMBHANI
# Script is used to set windows volume level.

Function Set-Speaker($Volume)
{
    $wshShell = new-object -com wscript.shell;1..50 | 
    % {$wshShell.SendKeys([char]174)};1..$Volume | 
    % {$wshShell.SendKeys([char]175)}
}

##Sets volume to 20%
Set-Speaker -Volume 10

##Sets volume to 40%
#Set-Speaker -Volume 20

##Sets volume to 60%
#Set-Speaker -Volume 30

##Sets volume to 80%
#Set-Speaker -Volume 40

##Sets volume to 100%
#Set-Speaker -Volume 50
