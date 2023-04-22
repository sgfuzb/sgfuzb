Import-Module DhcpServer 
$ServerList = 'MEHDC1','MEHDC2','MEHDC3','MEHDC4', 'MEHDCCRO', 'MEHDCNWP', 'MEHDCSTA'

$body = "Deleting bad leases" + [Environment]::NewLine;
$body += [Environment]::NewLine


Foreach($Server in $ServerList)
{
$ScopeList = Get-DhcpServerv4Scope -ComputerName $Server
    ForEach($Scope in $ScopeList.ScopeID) 
    {
        $ScopeInfo = Get-DhcpServerv4Scope -ComputerName $Server -ScopeId $Scope
        $leases = Get-DhcpServerv4Lease -ComputerName $Server -ScopeID $Scope | where hostname -eq "BAD_ADDRESS"
        
        $body += $scopeinfo.name + " " + $leases.Count + [Environment]::NewLine;

        if ($leases.Count -gt 0){
            
            
            Remove-DhcpServerv4Lease -BadLeases -ComputerName $Server -ScopeID $Scope
        }
    }
}

$smtpServer = "127.0.0.1"

$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

$msg.From = "it.alerts@moorfields.nhs.uk"
$msg.To.Add("moorfields.italerts@nhs.net")
$msg.Subject = "[DHCP Bad Leases Cleared]"
$msg.Body = $body
$smtp.Send($msg)
