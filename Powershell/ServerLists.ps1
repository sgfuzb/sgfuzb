start-transcript -Path "C:\PowerShell\ServerLists.log" -force

import-module virtualmachinemanager
import-module ActiveDirectory

$WhatIfPreference = $false

$Body = "[Server Tiers and TestDev Status]" + [Environment]::NewLine + [Environment]::NewLine

<#### MEHSCVMM

$dataSource = "MEHSCVMM2"
$database = "VirtualManagerDB"
$query = "SELECT        REPLACE(tbl_WLC_VMInstance.ComputerName, '.moorfields.nhs.uk', '') AS ServerName, tbl_BTBS_CustomPropertyValue.Value AS Tier
FROM            tbl_WLC_VMInstance LEFT OUTER JOIN
tbl_BTBS_CustomPropertyValue ON tbl_WLC_VMInstance.ObjectId = tbl_BTBS_CustomPropertyValue.ObjectID
WHERE        (tbl_BTBS_CustomPropertyValue.CustomPropertyID = '83e30e96-4e4e-4611-a10e-06f7a0599514')"

$connection = New-Object System.Data.SqlClient.SqlConnection
 $connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
 $connection.Open()
 $command = $connection.CreateCommand()
 $command.CommandText = $query
$result = $command.ExecuteReader()
$VMMtable = new-object "System.Data.DataTable"
$VMMtable.Load($result)
$connection.Close()
#>

<#
# old SP
$dataSource = "SP\SP"
$database = "WSS_Content"
$query = "SELECT  [tp_ColumnSet].value(N'/nvarchar1[1]', 'nvarchar(30)') as [ServerName],
[tp_ColumnSet].value(N'/nvarchar8[1]', 'nvarchar(30)') as [IPaddress],
[tp_ColumnSet].value(N'/nvarchar9[1]', 'nvarchar(30)') as [Owner],
[tp_ColumnSet].value(N'/nvarchar4[1]', 'nvarchar(30)') as [LiveTest],
[tp_ColumnSet].value(N'/nvarchar11[1]', 'nvarchar(30)') as [SerialNo],
[tp_ColumnSet].value(N'/nvarchar6[1]', 'nvarchar(30)') as [Tier],
[tp_ColumnSet].value(N'/nvarchar3[1]', 'nvarchar(30)') as [OS],
[tp_ColumnSet].value(N'/nvarchar7[1]', 'nvarchar(30)') as [PhyLoc],
[tp_ColumnSet].value(N'/bit1[1]', 'bit') as [isPhysical],
[tp_ColumnSet].value(N'/nvarchar5[1]', 'nvarchar(30)') as [Criticality]
  FROM [WSS_Content].[dbo].[UserData]
  where tp_ListId = 'A4434257-7051-43D2-905D-8E82AD2651D0'
  ORDER BY Servername"
#>

#### Sharepoint Server List
$dataSource = "SP2019\SP2019"
$database = "WSS_Content_SP2016"
$query = "SELECT  [tp_ColumnSet].value(N'/nvarchar1[1]', 'nvarchar(30)') as [ServerName],
[tp_ColumnSet].value(N'/nvarchar8[1]', 'nvarchar(30)') as [IPaddress],
[tp_ColumnSet].value(N'/nvarchar9[1]', 'nvarchar(30)') as [Owner],
[tp_ColumnSet].value(N'/nvarchar4[1]', 'nvarchar(30)') as [LiveTest],
[tp_ColumnSet].value(N'/nvarchar11[1]', 'nvarchar(30)') as [SerialNo],
[tp_ColumnSet].value(N'/nvarchar6[1]', 'nvarchar(30)') as [Tier],
[tp_ColumnSet].value(N'/nvarchar3[1]', 'nvarchar(30)') as [OS],
[tp_ColumnSet].value(N'/nvarchar7[1]', 'nvarchar(30)') as [PhyLoc],
[tp_ColumnSet].value(N'/bit1[1]', 'bit') as [isPhysical],
[tp_ColumnSet].value(N'/nvarchar5[1]', 'nvarchar(30)') as [Criticality]
  FROM [WSS_Content_SP2016].[dbo].[UserData]
  where tp_ListId = 'A4434257-7051-43D2-905D-8E82AD2651D0'
  ORDER BY Servername"

$connection = New-Object System.Data.SqlClient.SqlConnection
 $connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
 $connection.Open()
 $command = $connection.CreateCommand()
 $command.CommandText = $query

$result = $command.ExecuteReader()

$SPtable = new-object "System.Data.DataTable"
$SPtable2 = new-object "System.Data.DataTable"
$SPtable.Load($result)

$connection.Close()


$VMMServer = Get-VMMServer -ComputerName "MEHSCVMM19"
$VMs = @(Get-VM) # convert to array

# Report VMs in sharepoint but not on VMM

$body += [Environment]::NewLine
$body += "VMs in sharepoint but not on VMM" + [Environment]::NewLine

foreach ($SPDet in $SPtable)
{   
    $VMsFilter = @($VMs | Where-Object {$_.Name -eq $SPDet.ServerName})
    
    if (!$VMsFilter)
    {
    # no match in VMM, check if physical
        if (!$SPDet.isPhysical)
        {
            #VM in sharepoint but not on VMM:
            $body += $SPDet.ServerName + [Environment]::NewLine
            #write-host $SPDet.ServerName + [Environment]::NewLine
            #break;
        }
    }
}

# Report VMs live but not in sharepoint, update VMM with Tier and TestDev (no semi colons in heading!)

$body += [Environment]::NewLine
$body += "VMs in VMM but not on Server list in sharepoint" + [Environment]::NewLine
$VMCount = 0

# Update VMM custom properties

foreach ($VM in $VMs)
{   
    $SPDet = @($SPtable | Where-Object {$_.ServerName -eq $VM.Name})
  
    if ($SPDet -ne 0)
    {
        Write-Host "Setting property on VM", $VM.Name, $SPDet.Tier, $SPDet.LiveTest "..."

        $customPropertyTier = Get-SCCustomProperty -Name "Tier"
        $customPropertyTestDev = Get-SCCustomProperty -Name "LiveOrTest"
		$customPropertyCriticality = Get-SCCustomProperty -Name "Criticality"
		
        if ((Get-SCCustomPropertyValue -CustomProperty $customPropertyTier -InputObject $VM).Value -ne $SPDet.Tier) {
            Set-SCCustomPropertyValue -CustomProperty $customPropertyTier -InputObject $VM -Value $SPDet.Tier
        }
        if ((Get-SCCustomPropertyValue -CustomProperty $customPropertyTestDev -InputObject $VM).Value -ne $SPDet.LiveTest) {
        Set-SCCustomPropertyValue -CustomProperty $customPropertyTestDev -InputObject $VM -Value $SPDet.LiveTest
        }
        if ((Get-SCCustomPropertyValue -CustomProperty $customPropertyCriticality -InputObject $VM).Value -ne $SPDet.Criticality) {
		Set-SCCustomPropertyValue -CustomProperty $customPropertyCriticality -InputObject $VM -Value $SPDet.Criticality
        }

        # Cluster Start Priority
        # High (3000) - Critical, Essential
        # Medium (2000) - Important
        # Low (1000) - Low
        # No Auto Start (0) - NoSTart

        Write-Host $SPDet.Criticality

        switch ($SPDet.Criticality)
        {
            #Critical, Essential
            "High" {
                If((Get-SCVirtualMachine -ID $vm.id).HAVMPriority -ne 3000) {
                    Set-SCVirtualMachine -VM $VM -HAVMPriority 3000 
                }
            }
            #Important
            "Medium" {
                If((Get-SCVirtualMachine -ID $vm.id).HAVMPriority -ne 2000) {
                    Set-SCVirtualMachine -VM $VM -HAVMPriority 2000 
                }
            }
            #Low
            "Low" {
                If((Get-SCVirtualMachine -ID $vm.id).HAVMPriority -ne 1000) {
                    Set-SCVirtualMachine -VM $VM -HAVMPriority 1000 
                }
            }
            "NoStart" {
                If((get-SCVirtualMachine -ID $vm.id).HAVMPriority -ne 0) {
                    Set-SCVirtualMachine -VM $VM -HAVMPriority 0 
                }
            }
            default {
                If((get-SCVirtualMachine -ID $vm.id).HAVMPriority -ne 2000) {
                    Set-SCVirtualMachine -VM $VM -HAVMPriority 2000 
                }
            }
        }

        $VMCount++

    } else {
        # VM in VMM but not on sharepoint:
        $body += $VM.Name + [Environment]::NewLine
    }
}


$body += [Environment]::NewLine
$body += "http://mehsharepoint/it_servicedesk/Server_Inventory/_layouts/15/start.aspx#/Lists/Servers/AllItems.aspx" + [Environment]::NewLine
$body += [Environment]::NewLine

$body += [Environment]::NewLine
$body += "Updated (" + $VMCount + ") VMs in VMM with new Tier & TestDev status" + [Environment]::NewLine + [Environment]::NewLine


# Check if servers are in AD to avoid errors

foreach ($SP in $SPtable) {
    try {
        $test = Get-ADComputer -Identity $SP.Servername -ErrorAction Stop
        if ($test){
            $SPTable2 += $SP
        }
      } catch {
        Write-Host $SP.Servername Not in AD
      }
}

$tier4servers = $SPtable2 | Where-Object {$_.Tier -eq 4}
$tier3servers = $SPtable2 | Where-Object {$_.Tier -eq 3}
$tier2servers = $SPtable2 | Where-Object {$_.Tier -eq 2}
$tier1servers = $SPtable2 | Where-Object {$_.Tier -eq 1}
$tier0servers = $SPtable2 | Where-Object {$_.Tier -eq 0}

$body += [Environment]::NewLine + "Tier 4 Servers (" + $tier4servers.Count + ")" + [Environment]::NewLine 
$body += $tier4servers | Format-Table servername | Out-String

$body += [Environment]::NewLine + "Tier 3 Servers (" + $tier3servers.Count + ")" + [Environment]::NewLine 
$body += $tier3servers | Format-Table servername | Out-String

$body += [Environment]::NewLine + "Tier 2 Servers (" + $tier2servers.Count + ")" + [Environment]::NewLine 
$body += $tier2servers | Format-Table servername | Out-String

$body += [Environment]::NewLine + "Tier 1 Servers (" + $tier1servers.Count + ")" + [Environment]::NewLine 
$body += $tier1servers | Format-Table servername | Out-String

$body += [Environment]::NewLine + "Tier 0 Servers (" + $tier0servers.Count + ")" + [Environment]::NewLine 
$body += $tier0servers | Format-Table servername | Out-String

$body += "Adding to AD Groups" + [Environment]::NewLine
$body += [Environment]::NewLine

try {
    $Group = "Servers-Tier4"
    $body += $group
    Set-ADGroup -identity $Group -Clear member
    $tier4servers | ForEach-Object {Add-ADGroupMember -Identity $Group -Members ($_.Servername + "$") -ErrorVariable +err}
    Add-ADGroupMember -Identity $Group -Members "Servers-Tier4-Manual"
    $body += $err
    $err = ""
} catch { Write-Host "Error adding to tier4"}

try{
    $Group = "Servers-Tier3"
    $body += $group
    Set-ADGroup -identity $Group -Clear member
    $tier3servers | ForEach-Object {Add-ADGroupMember -Identity $Group -Members ($_.Servername + "$") -ErrorVariable +err}
    $body += $err
    $err = ""
} catch { Write-Host "Error adding to tier3"}

try {
    $Group = "Servers-Tier2"
    $body += $group
    Set-ADGroup -identity $Group -Clear member
    $tier2servers | ForEach-Object {Add-ADGroupMember -Identity $Group -Members ($_.Servername + "$") -ErrorVariable +err}
    $body += $err
    $err = ""
} catch { Write-Host "Error adding to tier2"}

try {
    $Group = "Servers-Tier1"
    $body += $group
    Set-ADGroup -identity $Group -Clear member
    $tier1servers | ForEach-Object {Add-ADGroupMember -Identity $Group -Members ($_.Servername + "$") -ErrorVariable +err}
    $body += $err
    $err = ""
} catch { Write-Host "Error adding to tier1"}

$body += [Environment]::NewLine
$body += "Updated tier groups in AD with tier members from sharepoint " + [Environment]::NewLine + [Environment]::NewLine
$body += [Environment]::NewLine

$body += "Checking against Pingmon and Solarwinds [not yet implemented]" + [Environment]::NewLine + [Environment]::NewLine
$body += [Environment]::NewLine
$body += "[END]" + [Environment]::NewLine

#Send email report

$subjectTxt = "[Server Tiers and TestDev Status]"

write-host $body

#$smtpServer = "smtp.moorfields.nhs.uk"
$smtpServer = "127.0.0.1"

#$att = new-object Net.Mail.Attachment($file)
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

$msg.From = "it.alerts@moorfields.nhs.uk"
$msg.To.Add("moorfields.italerts@nhs.net")
$msg.Subject = $subjectTxt
$msg.Body = $body
#$msg.Attachments.Add($att)
$smtp.Send($msg)
#$att.Dispose()

Stop-Transcript