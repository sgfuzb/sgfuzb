# Working
Get-RDServer -ConnectionBroker "mehcb-02.moorfields.nhs.uk"
Get-RDSessionCollection -ConnectionBroker "mehcb-02.moorfields.nhs.uk"
Get-RDSessionCollection -CollectionName "Moorfields Remote Desktop" -ConnectionBroker "mehcb-02.moorfields.nhs.uk"

Get-RDSessionCollectionConfiguration -CollectionName "Moorfields Remote Desktop" -Client -ConnectionBroker "mehcb-02.moorfields.nhs.uk"

# List Current session host servers
Get-RDSessionHost -CollectionName "Moorfields Remote Desktop" -ConnectionBroker "mehcb-02.moorfields.nhs.uk"

# Remove session host server
Remove-RDSessionHost -SessionHost @("MEHRDS-55.moorfields.nhs.uk") -ConnectionBroker "mehcb-02.moorfields.nhs.uk" -Force

# Add session host server
Add-RDSessionHost -CollectionName "Moorfields Remote Desktop" -SessionHost "MEHRDS-55.moorfields.nhs.uk" -ConnectionBroker "mehcb-02.moorfields.nhs.uk"

# Set session host server
Set-RDSessionHost -SessionHost "MEHRDS-55.moorfields.nhs.uk" -NewConnectionAllowed Yes -ConnectionBroker "mehcb-02.moorfields.nhs.uk"


# Testing




