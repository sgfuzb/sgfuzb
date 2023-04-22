# Close app
#
# Powershell
# https://social.technet.microsoft.com/Forums/ie/en-US/4c8fad53-d7ad-4e9a-9569-454d9c793bd3/powershell-to-close-a-running-program-gracefully-without-uses-interact?forum=w7itprogeneral
#
# 

#Get-Process Notepad |   Foreach-Object { $_.CloseMainWindow() | Out-Null } | stop-process –force

taskkill /S localhost /U "<user>" /P "<password>" /F /IM "Notepad.exe"