# Specify the URL in $URL which you want get status.
# You will get the status of URL with Up or Down.
# https://github.com/VSKUMBHANI/PowerShell

$URL = 'http://google.com'
$CheckURL = Invoke-WebRequest -Uri $URL -Method Head -UseBasicParsing

if($CheckURL.StatusCode -eq '200')
{
    Write-Host 'Up'
}
else
{
    Write-Host 'Down'
}
