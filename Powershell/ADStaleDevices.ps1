#================================
#
#  Steven Gill 
#  06/02/19  CR0092220 - Initial release
#  20/08/19  SR0125206 - changed to 30 days
#  11/05/20  CR0169313 - added deleting really old devices
#
#================================

#TODO: tidy - move disabled in computers to stale, move active in stale to computers

$daysold = 30 # 30 days
$daysold2 = 365*5 # 5 years
$whatifpreference = 1 #debug=1, normal=0

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$message = $null
$stalecomputers = $null
$disabledcomputersnotinstale = $null
$reallystalecomputers = $null
$message = ""

# ===================================================
# Deal with computers not logged in for more than x days
# ===================================================

$Date = (Get-Date).AddDays(-$daysold)

$Message += "===================================================<br>"
$Message += "Disabling Computers that have not logged on for more than " + $daysold + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"

$stalecomputers = Get-ADComputer -Filter * -Properties LastLogontimestamp ,PasswordLastSet,Enabled,description,DNSHostName | 
select Name, DistinguishedName, description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp )}}, enabled,DNSHostName |
where { ($_.LastLogontimestamp  -le $Date) -and ($_.enabled -eq $true)} | Sort-Object DNSHostName

$Message += "Moving " + $stalecomputers.Length + " Computers to Computers_Stale OU <br><br>"
$Message += "Computername, LastLogontimestamp  <br><br>"

ForEach ($computer in $stalecomputers){

   if ($computer.description  -like "*Failover*") {
        #IS failover cluster account
        #$Message += $computer.DNSHostName.ToString() + ", Failover cluster account <br>"

    } else {
        #IS NOT failover cluster account

        # add -whatif for testing
        Disable-ADAccount -Identity $computer.DistinguishedName # Disable first otherwise moves!
        Move-ADObject -Identity $computer.DistinguishedName -TargetPath "OU=Computers_Stale,DC=moorfields,DC=nhs,DC=uk"

        $Message += $computer.DNSHostName.ToString() + ", " + $computer.LastLogontimestamp.ToString($cultureENGB) + "<br>"
    }
}

# ===================================================
# Deal with any other disabled devices and move to stale OU
# ===================================================

$disabledcomputersnotinstale = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description | 
where { ($_.DistinguishedName -notlike "*OU=Computers_Stale*") -and ($_.enabled -eq $false)} | Sort-Object DNSHostName

$Message += "===================================================<br>"
$Message += "Moving any other disabled computer accounts to stale<br><br>"

ForEach ($computer in $disabledcomputersnotinstale){

   if ($computer.description -like "*Failover*") {
        #IS failover cluster account
        #$Message += $computer.DNSHostName.ToString() + ", Failover cluster account <br>"

    } else {
        #IS NOT failover cluster account

        # add -whatif for testing
        Move-ADObject -whatif -Identity $computer.DistinguishedName -TargetPath "OU=Computers_Stale,DC=moorfields,DC=nhs,DC=uk"

        $Message += $computer.DNSHostName.ToString() + "<br>"
    }
}

# ===================================================
# Deal with any other enabled devices in stale and move to computers OU
# ===================================================

$disabledcomputersnotinstale = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description -SearchBase "OU=Computers_Stale,DC=moorfields,DC=nhs,DC=uk"| 
where { ($_.enabled -eq $true)} | Sort-Object DNSHostName

$Message += "===================================================<br>"
$Message += "Moving any enabled computer accounts in stale back up computers<br><br>"

ForEach ($computer in $disabledcomputersnotinstale){

   if ($computer.description -like "*Failover*") {
        #IS failover cluster account
        #$Message += $computer.DNSHostName.ToString() + ", Failover cluster account <br>"

    } else {
        #IS NOT failover cluster account

        # add -whatif for testing
        Move-ADObject -whatif -Identity $computer.DistinguishedName -TargetPath "CN=Computers,DC=moorfields,DC=nhs,DC=uk"

        $Message += $computer.DNSHostName.ToString() + "<br>"
    }
}

# ===================================================
# Deal with really old disabled devices and delete
# ===================================================

$Date = (Get-Date).AddDays(-$daysold2)

$reallystalecomputers = Get-ADComputer -Filter * -Properties PasswordLastSet,Enabled,description,LastLogontimestamp -SearchBase "OU=Computers_Stale,DC=moorfields,DC=nhs,DC=uk"| 
select Name, DistinguishedName, Description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, enabled | 
where { ($_.enabled -eq $false) -and (($_.LastLogontimestamp -le $Date) -or ($_.LastLogontimestamp -eq "1/1/1601"))} | Sort-Object name

$Message += "===================================================<br>"
$Message += "Deleting any disabled device older than " + $daysold2 + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"

ForEach ($computer in $reallystalecomputers){

   if ($computer.description -like "*Failover*") {
        #IS failover cluster account
        #$Message += $computer.DNSHostName.ToString() + ", Failover cluster account <br>"

    } else {
        #IS NOT failover cluster account

        # add -whatif for testing

        #Remove-ADObject -Identity $computer.DistinguishedName -Confirm:$false
        $Message += $computer.Name.ToString() + ", " + $computer.LastLogontimestamp.ToString($cultureENGB) + "<br>"

    }
}

# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"

$Message

#Settings for Email Message
$rptDate= Get-date 
if ($whatifpreference -eq 1) {$subjectprefix = "###TEST### " } else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "["+$subjectprefix+"AD Stale Computers on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net"
    #, "andrew.peters1@nhs.net"
    #To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters –BodyAsHtml
