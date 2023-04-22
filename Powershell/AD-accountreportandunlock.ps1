# dot scope includes
. "m:\powershell\account-lockout-pseventcomb.ps1"

$user ="MEHADMIN"

$nl = [System.Environment]::NewLine


Write-Host "Checking user: " $user

while ($true){

    # Check if account locked

    if((Get-ADUser -Identity $user -Properties LockedOut).LockedOut){

        $Message = "===================================================" + $nl
        $Message += (get-date).tostring() + $user + " Locked out from one of these machines; " + $nl

        # Unlock account
        Unlock-ADAccount -Identity $user  

        # See where locked

        $message += Get-AccountLockoutStatus -DaysFromToday 1 -Username $user | out-string

        $Message += "===================================================" + $nl
        $Message += "DONE!" + $nl

        $Message
        
        $rptDate = Get-date
        if ($whatifpreference -eq 1) {$subjectprefix = "###TEST### " } else {$subjectprefix = "" } 

        $messageParameters = @{ 
            Subject = "["+$subjectprefix+"MEHADMIN Lockout " + $rptDate.ToString($cultureENGB) + "]"
            Body = $Message
            From = "it.alerts@moorfields.nhs.uk" 
            To = "moorfields.italerts@nhs.net"
            #To = "sg@nhs.net"
            SmtpServer = "smtp.moorfields.nhs.uk"
            #SmtpServer = "127.0.0.1"
        } 
        
        Send-MailMessage @messageParameters

    } else {
        Write-Host (get-date) " - Not Locked"
    }

    start-sleep 5

}