Get-ADuser -Filter * -SearchBase "CN=Users,DC=moorfields,DC=nhs,DC=uk" -Properties enabled, SamAccountName, title, GivenName , Surname, mail, telephoneNumber, mobile, department, description, company, manager | where enabled -eq $true | select SamAccountName, title, GivenName , Surname, mail, telephoneNumber, mobile, department, description, company, manager 
#| Export-Csv C:\users\gills\Desktop\ADUsers.csv -NoTypeInformation

