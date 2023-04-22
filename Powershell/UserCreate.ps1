Import-module activedirectory  

$whatifpreference = $true

$Users = Import-Csv -Path UserCreate.csv
$OU= "OU=Users,DC=moorfields,DC=nhs,DC=uk"

foreach ($User in $Users) {
    $Displayname =  $User.Lastname + ", " +  $User.Firstname
    $UserFirstname = $User.Firstname 
    $UserLastname = $User.Lastname             
    $OU = $User.OU 
    $SAM = $User.Lastname +  $user.Firstname.Substring(0,1)
    #$UPN = $UserFirstname.Substring(1,1) + $User.Lastname + "@" + $User.Maildomain             
    $Description = $User.Description             
    $Password = $User.Password 
         
    try {
    New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path "$OU" -ChangePasswordAtLogon $false –PasswordNeverExpires $true
    } catch {
        Write-Host "Error!" 
    }
    $Displayname 
}