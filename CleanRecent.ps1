Function Clear-RecentItems {
    $Namespace = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"
    $QuickAccess = New-Object -ComObject shell.application
    $RecentFiles = $QuickAccess.Namespace($Namespace).Items()
    $RecentFiles | % {$_.InvokeVerb("remove")}

    Remove-Item -Force "${env:USERPROFILE}\AppData\Roaming\Microsoft\Windows\Recent\*.lnk"

    New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0 -PropertyType DWORD
    Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs"
}
Clear-RecentItems
