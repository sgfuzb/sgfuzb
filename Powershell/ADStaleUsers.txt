# ===================================================
#
#  Steven Gill sg@nhs.net
#  21/08/19 CR0092220 - Initial release
#  05/09/19 SR0128795 - Added 90 day section
#  09/09/19 updated deletion and added never logged on disabled accounts
#  20/03/20 updated to disable not-logged-on users
#
# ===================================================
#
#  ToDo: 
#
# ===================================================
# Initialisation
# ===================================================

$daysold = 30 # disable after x days
$daysold2 = 90 # disable after x days (exceptions)
$daysold3 = [int](365.25*5) # delete after 5 years
$daysold4 = 365 # service accounts cutoff

$whatifpreference = $True #debug=$True, normal=$False

$StaleUserADPath = "OU=Users_Stale,DC=moorfields,DC=nhs,DC=uk"
$EmailFrom = "it.alerts@moorfields.nhs.uk"
$EmailTo = "moorfields.italerts@nhs.net", "andrew.peters1@nhs.net"
$EmailSMTP = "smtp.moorfields.nhs.uk"

# ===================================================
# Setup
# ===================================================

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$message = $null
$staleusers = $null
$staleUsers = $null

$Message = "<br>"

# ===================================================
# Deal with users not logged in for more than 30 days
# ===================================================

$Date = (Get-Date).AddDays(-$daysold)

$Message += "===================================================<br>"
$Message += "Disabling Users in Users OU that have not logged in for more than " + $daysold + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"

$staleUsers = Get-ADuser -Filter * -Properties LastLogontimestamp,lastLogon,Enabled,description -SearchBase "CN=Users,DC=moorfields,DC=nhs,DC=uk"| 
Select-Object Name, DistinguishedName, Description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, enabled | 
Where-Object { ($_.LastLogontimestamp -le $Date) -and ($_.enabled -eq $true) -and ($_.LastLogontimestamp -gt "1/1/1601")} | Sort-Object name

$Message += "Disabling and Moving " + $staleUsers.Length + " Users to Users_Stale OU <br><br>"
$Message += "Username, LastLogontimestamp <br><br>"

ForEach ($user in $staleUsers){

    Disable-ADAccount -Identity $user.DistinguishedName 
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath

    $Message += $user.Name.ToString() + ", " + $user.LastLogontimestamp.ToString($cultureENGB) + "<br>"
}

# ===================================================
# Deal with users not logged in for more than 90 days
# ===================================================

$Date = (Get-Date).AddDays(-$daysold2)

$Message += "===================================================<br>"
$Message += "Disabling Users in Users_90dayStale OU that have not logged in for more than " + $daysold2 + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"

$staleUsers = Get-ADuser -Filter * -Properties LastLogontimestamp,lastLogon,Enabled,description -SearchBase "OU=Users_90dayStale,DC=moorfields,DC=nhs,DC=uk"| 
Select-Object Name, DistinguishedName, Description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, enabled | 
Where-Object { ($_.LastLogontimestamp -le $Date) -and ($_.enabled -eq $true) -and ($_.LastLogontimestamp -gt "1/1/1601")} | Sort-Object name

$Message += "Disabling and Moving " + $staleUsers.Length + " Users to Users_Stale OU <br><br>"
$Message += "Username, LastLogontimestamp <br><br>"

ForEach ($user in $staleUsers){

    Disable-ADAccount -Identity $user.DistinguishedName 
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath

    $Message += $user.Name.ToString() + ", " + $user.LastLogontimestamp.ToString($cultureENGB) + "<br>"
}

# ===================================================
# Deal with any other disabled users and move to stale OU
# ===================================================

$disabledusersnotinstale = Get-ADuser -Filter * -Properties Enabled,description | 
Where-Object { ($_.DistinguishedName -notlike "*OU=Users_Stale*") -and ($_.DistinguishedName -notlike "*OU=users_exchange*") -and($_.enabled -eq $false)} | Sort-Object Name

$Message += "===================================================<br>"
$Message += "Moving " + $disabledusersnotinstale.Count + " disabled User accounts in other OUs to Users_Stale<br><br>"
$Message += "<br>"

ForEach ($user in $disabledusersnotinstale){

    Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath
    $Message += $user.Name.ToString() + "<br>"
}

$Message += "<br>"

# ===================================================
# Deal with any disabled really old users not logged in for 5yrs and delete
# ===================================================

$Date = (Get-Date).AddDays(-$daysold3)

$Message += "===================================================<br>"
$Message += "Deleting Users that have not logged in for more than " + $daysold3 + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"
$Message += "<br>"

$staleUsers = Get-ADuser -Filter * -Properties LastLogontimestamp,Enabled,description -SearchBase $StaleUserADPath| 
Select-Object Name, DistinguishedName, Description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, enabled | 
Where-Object { ($_.LastLogontimestamp -le $Date) -and ($_.enabled -eq $false) -and ($_.LastLogontimestamp -gt "1/1/1601")} | Sort-Object name

$Message += "Deleting " + $staleUsers.Length + " Users <br><br>"
$Message += "Username, LastLogon <br><br>"

ForEach ($user in $staleUsers){

    Remove-ADObject -Identity $user.DistinguishedName -Confirm:$false
    $Message += $user.Name.ToString() + ", " + $user.LastLogontimestamp.ToString($cultureENGB) + "<br>"
}

# ===================================================
# Deal with any users never logged in created over x days ago
# ===================================================

$Date = (Get-Date).AddDays(-$daysold2)

$Message += "===================================================<br>"
$Message += "Disabling users that have never logged in and were created over " + $daysold2 + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br><br>"
$Message += "<br>"

$staleUsers = Get-ADuser -Filter * -Properties LastLogontimestamp,lastLogon,Enabled,description,whencreated -SearchBase "CN=Users,DC=moorfields,DC=nhs,DC=uk"| 
Select-Object Name, DistinguishedName, Description, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, whencreated, enabled | 
Where-Object { ($_.LastLogontimestamp -le $Date) -and ($_.enabled -eq $true) -and ($_.LastLogontimestamp -le "1/1/1601") -and ($_.whencreated -le $date)} | Sort-Object name

$Message += "Disabling and Moving " + $staleUsers.Length + " Users to Users_Stale OU <br><br>"
$Message += "Username, Created <br><br>"

ForEach ($user in $staleUsers){

    Disable-ADAccount -Identity $user.DistinguishedName 
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath

    $Message += $user.Name.ToString() + ", " + $user.whencreated.ToString($cultureENGB) + "<br>"
}

# ===================================================
# Deal with Service Accounts last password change >365 days
# ===================================================

$Date = (Get-Date).AddDays(-$daysold4)

$Message += "===================================================<br>"
$Message += "Service Accounts Cutoff : " + $daysold4 + " Days (Before: "+$Date.ToString($cultureENGB)+ ")<br>"

$serviceaccounts = Get-ADuser -Filter * -Properties pwdLastSet,LastLogontimestamp,lastLogon,Enabled,description,whencreated -SearchBase "OU=ServiceAccounts,DC=moorfields,DC=nhs,DC=uk"| 
Select-Object Name, DistinguishedName, @{Label = "Description"; Expression = { if ($_.Description) { $_.Description } else { "" } }}, @{Name='LastLogontimestamp';Expression={[DateTime]::FromFileTime($_.LastLogontimestamp)}}, @{Name='pwdLastSet';Expression={[DateTime]::FromFileTime($_.pwdLastSet)}}, whencreated, enabled | 
Where-Object {  ($_.enabled -eq $true) -and ($_.whencreated -le $date)} 

$staleusers_never = $serviceaccounts | Where-Object {($_.LastLogontimestamp -le "1/1/1601")} | Sort-Object Name
$staleusers_lastlog = $serviceaccounts | Where-Object {($_.LastLogontimestamp -le $Date) -and ($_.LastLogontimestamp -gt "1/1/1601")} | Sort-Object LastLogontimestamp,Name
$staleusers_lastpass = $serviceaccounts | Where-Object {($_.pwdLastSet -le $Date) -and ($_.LastLogontimestamp -gt "1/1/1601")} | Sort-Object pwdLastSet,Name


# Never logged in => disable and stale
$Message += "===================================================<br>"
$Message += "Service Accounts Never logged in, disabling and moving " + $staleusers_never.Length + " Users to Users_Stale OU [disabled]<br><br>"
$Message += "Username, Created, LastLogontimestamp, pwdLastSet, description <br><br>"
ForEach ($user in $staleusers_never ){
    #Disable-ADAccount -Identity $user.DistinguishedName 
    #Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath
    $Message += $user.Name.ToString() + "," + $user.whencreated.ToShortDateString() + "," + $user.LastLogontimestamp.ToShortDateString() + "," + $user.pwdLastSet.ToShortDateString() + "," + $user.description.ToString() +"<br>"
}

# lastlogon > date => disable and stale
$Message += "===================================================<br>"
$Message += "Service accounts not logged on in timeframe, disabling and moving " + $staleusers_lastlog.Length + " Users to Users_Stale OU [disabled]<br><br>"
$Message += "Username, Created, LastLogontimestamp, pwdLastSet, Description <br><br>"
ForEach ($user in $staleusers_lastlog){
    #Disable-ADAccount -Identity $user.DistinguishedName 
    #Move-ADObject -Identity $user.DistinguishedName -TargetPath $StaleUserADPath
    $Message += $user.Name.ToString() + "," + $user.whencreated.ToShortDateString() + "," + $user.LastLogontimestamp.ToShortDateString() + "," + $user.pwdLastSet.ToShortDateString() + "," + $user.description.ToString() +"<br>"
}

# pwdlastset > date => for info/review
$Message += "===================================================<br>"
$Message += "Service accounts not changed pw in timeframe and in need of review, " + $staleusers_lastpass.Length + "  <br><br>"
$Message += "Username, Created, LastLogontimestamp, pwdLastSet, Description <br><br>"
ForEach ($user in $staleusers_lastpass){

    $Message += $user.Name.ToString() + "," + $user.whencreated.ToShortDateString() + "," + $user.LastLogontimestamp.ToShortDateString() + "," + $user.pwdLastSet.ToShortDateString() + "," + $user.description.ToString() +"<br>"
}



# ===================================================
# Report and email
# ===================================================

$Message += "===================================================<br>"
$Message += "DONE!<br>"


#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq $True) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "AD Stale Users on " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = $EmailFrom
    To = $EmailTo
    SmtpServer = $EmailSMTP

} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
