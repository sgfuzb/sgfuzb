# From 
# https://www.itprotoday.com/powershell/changing-service-credentials-using-powershell 
# https://techibee.com/powershell/powershell-how-to-get-logon-account-of-services-on-remote-computer/1228

# Use pdq report for list of service accounts
# Manually add account for logon as service right! (too complicated in PS)

function Set-ServiceCredential {
  param(
    [String] $ServiceName,
    [String] $ComputerName,
    [Management.Automation.PSCredential] $ServiceCredential,
    [Management.Automation.PSCredential] $connectionCredential
  )
  # Get computer name if passed by property name.
  if ( $computerName.ComputerName ) {
    $computerName = $computerName.ComputerName
  }
  # Empty computer name or . is local computer.
  if ( (-not $computerName) -or $computerName -eq "." ) {
    $computerName = [Net.Dns]::GetHostName()
  }
  $wmiFilter = "Name='{0}' OR DisplayName='{0}'" -f $serviceName
  $params = @{
    "Namespace"    = "root\CIMV2"
    "Class"        = "Win32_Service"
    "ComputerName" = $computerName
    "Filter"       = $wmiFilter
    "ErrorAction"  = "Stop"
  }
  if ( $connectionCredential ) {
    # Specify connection credentials only when not connecting to the local computer.
    if ( $computerName -ne [Net.Dns]::GetHostName() ) {
      $params.Add("Credential", $connectionCredential)
    }
  }
  try {
    $service = Get-WmiObject @params
  }
  catch [Management.Automation.RuntimeException],[Runtime.InteropServices.COMException] {
    Write-Error "Unable to connect to '$computerName' due to the following error: $($_.Exception.Message)"
    return
  }
  if ( -not $service ) {
    Write-Error "Unable to find service named '$serviceName' on '$computerName'."
    return
  }
  # See https://msdn.microsoft.com/en-us/library/aa384901.aspx
  $returnValue = ($service.Change($null,                 # DisplayName
    $null,                                               # PathName
    $null,                                               # ServiceType
    $null,                                               # ErrorControl
    $null,                                               # StartMode
    $null,                                               # DesktopInteract
    $serviceCredential.UserName,                         # StartName
    $serviceCredential.GetNetworkCredential().Password,  # StartPassword
    $null,                                               # LoadOrderGroup
    $null,                                               # LoadOrderGroupDependencies
    $null)).ReturnValue                                  # ServiceDependencies
  $errorMessage = "Error setting credentials for service '$serviceName' on '$computerName'"
  switch ( $returnValue ) {
    0  { Write-Verbose "Set credentials for service '$serviceName' on '$computerName'" }
    1  { Write-Error "$errorMessage - Not Supported" }
    2  { Write-Error "$errorMessage - Access Denied" }
    3  { Write-Error "$errorMessage - Dependent Services Running" }
    4  { Write-Error "$errorMessage - Invalid Service Control" }
    5  { Write-Error "$errorMessage - Service Cannot Accept Control" }
    6  { Write-Error "$errorMessage - Service Not Active" }
    7  { Write-Error "$errorMessage - Service Request timeout" }
    8  { Write-Error "$errorMessage - Unknown Failure" }
    9  { Write-Error "$errorMessage - Path Not Found" }
    10 { Write-Error "$errorMessage - Service Already Stopped" }
    11 { Write-Error "$errorMessage - Service Database Locked" }
    12 { Write-Error "$errorMessage - Service Dependency Deleted" }
    13 { Write-Error "$errorMessage - Service Dependency Failure" }
    14 { Write-Error "$errorMessage - Service Disabled" }
    15 { Write-Error "$errorMessage - Service Logon Failed" }
    16 { Write-Error "$errorMessage - Service Marked For Deletion" }
    17 { Write-Error "$errorMessage - Service No Thread" }
    18 { Write-Error "$errorMessage - Status Circular Dependency" }
    19 { Write-Error "$errorMessage - Status Duplicate Name" }
    20 { Write-Error "$errorMessage - Status Invalid Name" }
    21 { Write-Error "$errorMessage - Status Invalid Parameter" }
    22 { Write-Error "$errorMessage - Status Invalid Service Account" }
    23 { Write-Error "$errorMessage - Status Service Exists" }
    24 { Write-Error "$errorMessage - Service Already Paused" }
  }
}
function Get-ServiceLogonAccount {
  [cmdletbinding()]            
  
  param (
  $ComputerName = $env:computername,
  $LogonAccount
  )            
  
      if($logonAccount) {
          Get-WmiObject -Class Win32_Service -ComputerName $ComputerName | Where-Object { $_.StartName -match $LogonAccount } | Select-Object DisplayName, StartName, State
  
      } else {            
  
          Get-WmiObject -Class Win32_Service -ComputerName $ComputerName | Select-Object DisplayName, StartName, State
      }
}

####################################

$UserName = "CITY_ROAD\SQLClusterAgent"
$PlainPassword = "sb+tZmG-uSA,"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword

$Servers = "MEHSQL1","MEHSQL2","MEHSQL3","MEHSQL4"

ForEach ($Server in $Servers) {

  # Sort so does agents first
  $services = Get-ServiceLogonAccount -ComputerName $Server -LogonAccount "SQLClusterAgent" | Sort-Object -Property Displayname -Descending

  # Change Credential

  ForEach ($service in $services) {
    Write-Host Updating: $service.DisplayName
    Set-ServiceCredential -ComputerName $Server -ServiceName $service.DisplayName -ServiceCredential $Credentials -Confirm:$false

  }

}

Write-Host "Now fail SQL instances over and back"

<#
#$servicesStopped = $services | where-object {$_.State -eq "Stopped"} 

#$servicesStartedAgents = $services | where-object {($_.State -eq "Running")-and ($_.Displayname -match "Agent")} 

ForEach ($service in $servicesStopped) {
  Write-Host Updating: $service.DisplayName
  Set-ServiceCredential -serviceName $service.DisplayName -ServiceCredential $Credentials -Confirm:$false

}

ForEach ($service in $servicesStartedAgents) {
  Write-Host Updating: $service.DisplayName
  Set-ServiceCredential -serviceName $service.DisplayName -ServiceCredential $Credentials -Confirm:$false

}
#>

#$roles = Get-ClusterGroup | Where-Object {$_.Name -like "SQL Server*"}

# Stop all Roles
#ForEach ($role in $roles) {
#  Write-Host Stopping Role: $service.DisplayName
#  Stop-ClusterGroup $role
#}

# Start all Roles

#ForEach ($role in $roles) {
#  Write-Host Starting Role: $service.DisplayName
#  Start-ClusterGroup $role
#}