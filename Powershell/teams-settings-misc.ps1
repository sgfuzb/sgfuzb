# Teams open in the background Hidden $true or $false
[boolean]$OpenAsHidden=$False
# Teams open automatically at user login $true or $false
[boolean]$OpenAtLogin=$False
# Close Teams App fully instead of running on Taskbar $true or $false
[boolean]$RunningOnClose=$False

# Get Teams Configuration
$FileContent=Get-Content -Path "$ENV:APPDATA\Microsoft\Teams\desktop-config.json"
#$FileContent=Get-Content -path "$ENV:APPDATA\Microsoft\Teams\settings.json"
# Convert file content from JSON format to PowerShell object
$JSONObject=ConvertFrom-Json -InputObject $FileContent
# Update Object settings
$JSONObject.appPreferenceSettings.OpenAsHidden=$OpenAsHidden
$JSONObject.appPreferenceSettings.OpenAtLogin=$OpenAtLogin
$JSONObject.appPreferenceSettings.$RunningOnClose=$RunningOnClose
# Terminate Teams Process
Get-Process Teams | Stop-Process -Force
# Convert Object back to JSON format
$NewFileContent=$JSONObject | ConvertTo-Json
# Update configuration in file
$NewFileContent | Set-Content -Path "$ENV:APPDATA\Microsoft\Teams\desktop-config.json"

# https://devblogs.microsoft.com/scripting/configuring_startup_settings_in_microsoft_teams_with_windows_powershell/

# C:\Users\gills\AppData\Roaming\Microsoft\Teams
