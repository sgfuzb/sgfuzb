#############################################################
# Update AD User details from CSD
# Steven Gill
# Powershell version Dec 2022, original vbscript 2004
#############################################################

Import-Module ActiveDirectory

# Set Working Directory
if ($env:computername -eq "INTRANET3"){ Set-Location "C:\PowerShell" }
if ($env:computername -eq "M016815"){ Set-Location "M:\PowerShell" }

$cultureENGB = New-Object System.Globalization.CultureInfo("en-GB")
$Message = ""
$ADChanges = @()

# Transcript on (turn whatif off if on)
$WhatIfPreference = $false
Start-Transcript -Path ".\Update-ADUserDetails.log" -Force

############## WHATIF = true for DEBUG ###################
$WhatIfPreference = $true
##########################################################

Function Write-SGLog
{
    Param
    (
        [string] $SGlogMessage,
        [bool] $Verbose
    )

    If ($verbose) {
        #Write-Host (get-date) $SGlogMessage -ForegroundColor Magenta
    } else {
        Write-Host (get-date) $SGlogMessage -ForegroundColor Yellow
        #$global:Message += $SGlogMessage + "<br>"
    }
}
Function Sterilize {
    Param (
        [Parameter(Mandatory=$true)][AllowEmptyString()][String] $Value,
        [Parameter (Mandatory=$False)][int] $len = 64
    )

    If ($Value) {
        $Value = $Value.Trim()              # Trim
        $Value = $Value.replace("'","")     # No '
        $Value = $Value.replace("?","-")    # No ?
        $Value = $Value.replace("``","''")  # No `
        $Value = $Value.replace("\","")     # No \
        $Value = $Value.replace("`"","")    # No "
        $Value = $Value.replace(",","")     # No ,
        if($Value.Length -ge $len) {
            $Value = $Value.Substring(0,$len)     # <$len chars
        }
    } else {
        $Value = $null
    }

    if ($Value -eq "") { $Value = $null}

    Return $Value
}

#Sterilize("Hell'os??\\xxxxxx`"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx2342342343454564567")

function TrimString {
    param (
        [string] $String,
        [int] $StringLength
    )
    
    # Return a string of length specified or shorter, including ... for overruns

    $StrLen = $String.Length
    If ($StrLen -gt $StringLength) {
        $StrLen = $StringLength - 3
        $String = $String.ToString().Substring(0,$StrLen) + "..."
    } else {
        $String = $String.ToString()
    }

    Return $String
}

<#
TrimString -String "Hello" -StringLength 20
TrimString -String "HelloHelloHel" -StringLength 20
TrimString -String "HelloHelloHelloHelloHelloHello" -StringLength 20
#>

Write-SGLog -SGlogMessage ("Starting...")

# ===================================================
# Get CSD SQL view
# ===================================================

$dataSource = "intra3\intra3"
$database = "MEHCentralDatabase"
#$query = "SELECT * FROM [vwADUpdate] WHERE ((ntlogon <> '-') and (ntlogon not like 'XXX%')) ORDER by ntlogon,startingdate"
$query = "SELECT TOP 200 * FROM [vwADUpdate] WHERE ((ntlogon <> '-') and (ntlogon not like 'XXX%')) ORDER by ntlogon,startingdate"
#$query ="SELECT * FROM [vwADUpdate] WHERE ntlogon like 'A%' ORDER by ntlogon,startingdate"
#$query ="SELECT * FROM [vwADUpdate] WHERE (ntlogon = 'ABADOOD') or (ntlogon = 'SANYANGM') order by ntlogon,startingdate"

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = "Server=$dataSource;Database=$database;Integrated Security=True;"
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = $query
$result = $command.ExecuteReader()
$DataTable = new-object "System.Data.DataTable"
$DataTable.Load($result)
$connection.Close()

Write-SGLog -SGlogMessage ("Retrieved " + $datatable.Rows.Count + " CSD Records")

# ===================================================
# Get AD users
# ===================================================

$ADUsers = Get-ADUser -Filter * -Properties company,co,postofficebox,department,description,displayname,mail,extensionattribute1,extensionattribute4,givenname,l,manager,name,office,telephonenumber,physicaldeliveryofficename,postalcode,st,streetaddress,sn,thumbnailphoto,title
Write-SGLog -SGlogMessage ("Retrieved " + $ADUsers.Count + " AD Records") 

# ===================================================
# Get All needed Photos
# ===================================================

$ThumbnailPhotos = @()
$NeededPhotos = $dataTable | Where-Object {($_.cardid).length -gt 1} | Select-Object cardid

ForEach ($NeededPhoto in $NeededPhotos) {

    $PhotoFullName = "\\intranet3\MEHCentralDatabaseBadgePhotographs\" + $NeededPhoto.cardid + "-1.jpg"

    If (Test-Path $PhotoFullName) {
        $Photo = [byte[]](Get-Content $PhotoFullName -Encoding byte)
        If ($Photo.Length -lt 100000) {
            $ThumbnailPhotos += [PSCustomObject]@{
                CardID = $NeededPhoto.cardid
                Photo = $Photo
            }
        }
    }
}

Write-SGLog -SGlogMessage ("Retrieved " + $ThumbnailPhotos.Count + " Photos")

# ===================================================
# Update each user details
# ===================================================

ForEach ($CSDUser in $DataTable){

    # ===================================================
    # Pre-process Data
    # ===================================================

    $szNTLogon = $CSDUser.ntlogon.ToUpper()
    $szFirstName = Sterilize($CSDUser.firstname)
    $szLastName = Sterilize($CSDUser.lastname)
    $szKnownasFirst = Sterilize($CSDUser.knownasfirst)
    
    #$szKnownasLast = $szLastName
    if ($szKnownasFirst -eq "") {
        $szKnownasFirst = $szFirstName
    }

    #$szFullName = Sterilize($szFirstName + " " + $szLastName)
    $szDisplayName = (Sterilize($szLastName)) + ", " + (Sterilize($szKnownasFirst))
    
    # Jobtitle prefer ESR
    $szJobtitle = Sterilize($CSDUser.jobtitle)
    $szJobtitleesr = Sterilize($CSDUser.jobtitleesr)
    If ($szJobtitleesr) {
        $szJobtitle = $szJobtitleesr
    }
    If ($szJobtitle -eq "") { $szJobtitle = $null }

    # Phone Numbers
    $szTelephone = Sterilize($CSDUser.extn)
    #$szTelephone2 = Sterilize($CSDUser.extn2)
    #$szMobile = Sterilize($CSDUser.extnmob)

    # Department
    $szDepartment = Sterilize($CSDUser.department)
    $szDepartment2 = Sterilize($CSDUser.department2)
    $szDepartment3 = Sterilize($CSDUser.department3)

    # Starting and leaving Dates
    #$szleavingdate = $CSDUser.leavingdate.ToString($cultureENGB)
    #$szstartingdate = $CSDUser.startingdate.ToString($cultureENGB)
    if ($CSDUser.leavingdate -isnot [DBNull]) {
        $szleavingdate = $CSDUser.leavingdate.ToString("yyyy/MM/dd")
    } else {
        $szleavingdate = $null
    }
    if ($CSDUser.startingdate -isnot [DBNull]) {
        $szstartingdate = $CSDUser.startingdate.ToString("yyyy/MM/dd")
    } else {
        $szstartingdate = $null
    }
    if ($szstartingdate -eq "1900/01/01") { $szstartingdate = $null }
    if ($szleavingdate -eq "1900/01/01") { $szleavingdate = $null }

    # Left MEH
    if ((Sterilize($CSDUser.LeftMEH)) -eq "True") {
        $szLeftMEH = $true
    } else {
        $szLeftMEH = $false
    }


    # Manager DN, clear manager if left
    $szManNTLogon = Sterilize($CSDUser.ManNTLogon)
    if (($szManNTLogon) -and (-not $szLeftMEH)) {
        try {
            #$szManDN = (Get-ADUser -Identity $szManNTLogon).DistinguishedName
            $szManDN = $ADUsers | Where-Object {$_.samaccountname -eq $szManNTLogon}
        }
        catch {
            $szManDN = $null # Null if not exists
        }
    } else {
        $szManDN = $null # Null if not exists
    }


    # ID Card
    $szcardid = Sterilize($CSDUser.cardid)
    if ((Sterilize($CSDUser.showimage)) -eq "True") {
        $szshowimage = $true
    } else {
        $szshowimage = $false
    }

    If ($szcardid -eq "") {
        $szshowimage = $False
    }

    # CostCentre
    $szCostCentre = Sterilize($CSDUser.CostCentreCode)
    if ($szCostCentre -eq "") { $szCostCentre = $null }

    # Email
    $szEmail = Sterilize($CSDUser.emailaddress)

    # Location - first three words only
    if (Sterilize($CSDUser.location)) {
        $MaxWords = 3
        $words = @()
        $Words = ($CSDUser.location).Split(" ")
        $szLocation = ""
        $szLocation = $Words[0]
        $i=1
        While ($i -lt $MaxWords) {
            $szLocation = $szLocation + " " + $Words[$i]
            $i++
        }
        $szLocation = Sterilize($szLocation) 
        
        # Company if location
        $szCompany = "MEH-" + $szLocation
        $szCompany = Sterilize($szCompany)
    } else {
        # Company if no location
        $szCompany = "MEH-Unknown"
        $szLocation = "Unknown"
    }

    # Office
    $szOffice = $szLocation
    if (($szDepartment2) -and ($szDepartment2 -ne " ") -and ($szDepartment2 -ne "Unknown")) {
        $szOffice  += " - " + $szDepartment2
    }
    if (($szDepartment) -and ($szDepartment -ne " ") -and ($szDepartment -ne "Unknown")) {
        $szOffice  += " - " + $szDepartment
    }
    if (($szDepartment3) -and ($szDepartment3 -ne " ") -and ($szDepartment3 -ne "Unknown")) {
        $szOffice  += " - " + $szDepartment3
    }

    $szOffice = Sterilize -Value $szOffice -len 127  # 127 chars max in AD

    # Description - 1024 chars
    if ( $szLeftMEH ) {
        if ($null -ne $szleavingdate) {
            $szDescription = "USER LEFT: " + $szleavingdate + " *****************"
        } else {
            $szDescription = "USER LEFT: Unknown *****************"            
        }
        $szDepartment = $null # Blank department for Exchange distribution lists
    } else {
        $szDescription = $szDepartment + " - " + $szJobtitle
        if ($szTelephone -ne "") {
            $szDescription = $szDescription + " x" + $szTelephone
        }
    }
    $szDescription = Sterilize -Value $szDescription -len 1024 # 1024 chars max in AD
    
    # Photo
    # $Photo = [byte[]](Get-Content c:\image.jpg -Encoding byte)
    # Set-ADUser AARDVARKB -Replace @{thumbnailPhoto=$photo}
    If ($szshowimage){

        $szThumbnailPhoto = ($ThumbnailPhotos | Where-Object {$_.cardid -eq $szcardid}).photo
        
        if ($szThumbnailPhoto) {
            $szextensionAttribute1 = "http://intranet3/staffphotos/" + $szcardid + "-1.jpg"
        }

        <#
        $strImagePath = "\\intranet3\MEHCentralDatabaseBadgePhotographs\" + $szcardid + "-1.jpg"
        If (Test-Path $strImagePath) {
            $szThumbnailPhoto = [byte[]](Get-Content $strImagePath -Encoding byte)
            if ($szThumbnailPhoto.Length -gt 100000) {$szThumbnailPhoto = $null} # check if >100k
            $szextensionAttribute1 = "http://intranet3/staffphotos/" + $szcardid + "-1.jpg"
        }
        #>
    } else {
        $szThumbnailPhoto = $null
        $szextensionAttribute1 = $null
    }

    # ESR employeeID - Ext4
    if ($CSDUser.RESID -ne "-1") {
        $szRESID = Sterilize($CSDUser.RESID) 
        $szextensionAttribute4 = $szRESID
    } else {
        $szRESID = $null
        $szextensionAttribute4 = $null
    }
    if ($szRESID -eq "") { $szRESID = $null}
    if ($szextensionAttribute4 -eq "") { $szextensionAttribute4 = $null}

    # Static
    $szCity = "London"
    $szState = "London"
    $szStreetAddress = "162 City Road"
    $szPostalCode = "EC1V 2PD"
    $szCountry = "UNITED KINGDOM"
    #$szISOCountry = "GB"
    #$szCountryCode = "826"    

    # ===================================================
    # Process User
    # ===================================================
    
    # Check for user in AD

    $ADUser = $ADUsers | Where-Object { $_.SamAccountName -eq $szNTLogon }

    if ($ADUser) { 
        Write-SGLog ($szNTLogon + ": User in AD" ) -Verbose $true
    } else {
        Write-SGLog ($szNTLogon + ": User not in AD" ) -Verbose $true
        $ADUser = @()
    }

    <#
    Try {
        # Check user exists
        $ADUser = Get-ADUser -Identity $szNTLogon -Properties company,co,postofficebox,department,description,displayname,mail,extensionattribute1,extensionattribute4,givenname,l,manager,name,office,telephonenumber,physicaldeliveryofficename,postalcode,st,streetaddress,sn,thumbnailphoto,title
    }
    Catch {
        Write-SGLog ($szNTLogon + ": User not in AD" ) -Verbose $true
        $ADUser = @()
    }
    #>

    # if exists start update
    if ($ADUser) {

        # Default is Delta update (only update attrib if changed), Forceupdate will update even if not changed
        $ForceUpdate = $false
        $NTUser = $CSDUser.ntlogon

        $PropMap = @(
            @{  Desc = "Company" ; From = $ADUser.company ; To = $szCompany ; ADField = "company" },
            @{  Desc = "Country" ; From = $ADUser.co ; To = $szCountry ; ADField = "co" },
            @{  Desc = "CostCode" ; From = $ADUser.postofficebox ; To = $szCostCentre ; ADField = "postofficebox" },
            @{  Desc = "Department" ; From = $ADUser.department ; To = $szDepartment ; ADField = "department" },
            @{  Desc = "Description" ; From = $ADUser.Description ; To = $szDescription ; ADField = "description" },
            @{  Desc = "DisplayName" ; From = $ADUser.DisplayName ; To = $szDisplayName ; ADField = "displayName" },
            @{  Desc = "Email-Address" ; From = $ADUser.mail ; To = $szEmail ; ADField = "mail" },
            @{  Desc = "Ext1-PictureURL" ; From = $ADUser.extensionAttribute1  ; To = $szextensionAttribute1 ; ADField = "extensionattribute1" },
            @{  Desc = "Ext4-RESID" ; From = $ADUser.extensionAttribute4 ; To = $szextensionAttribute4 ; ADField = "extensionattribute4" },
            @{  Desc = "GivenName-FirstName" ; From = $ADUser.GivenName ; To = $szKnownasFirst; ADField = "givenName" },
            @{  Desc = "l-City" ; From = $ADUser.l ; To = $szCity ; ADField = "l" },
            @{  Desc = "Manager" ; From = $ADUser.manager ; To = $szManDN ; ADField = "manager" },
            @{  Desc = "Name" ; From = $ADUser.Name ; To = $szNTLogon ; ADField = "name" },
            @{  Desc = "Office" ; From = $ADUser.office ; To = $szOffice ; ADField = "office" },
            @{  Desc = "PhoneNumber" ; From = $ADUser.TelephoneNumber ; To = $szTelephone ; ADField = "telephoneNumber" },
            @{  Desc = "Physical-Office" ; From = $ADUser.physicalDeliveryOfficeName ; To = $szOffice ; ADField = "physicaldeliveryofficename" },
            @{  Desc = "Postcode" ; From = $ADUser.postalCode  ; To = $szPostalCode ; ADField = "postalcode" },
            @{  Desc = "State" ; From = $ADUser.st ; To = $szState ; ADField = "st" },
            @{  Desc = "Street" ; From = $ADUser.streetAddress ; To = $szStreetAddress ; ADField = "streetaddress" },
            @{  Desc = "Surname" ; From = $ADUser.sn ; To = $szLastName ; ADField = "sn" },
            @{  Desc = "Thumbnail-Photo" ; From = $ADUser.thumbnailPhoto ; To = $szThumbnailPhoto ; ADField = "thumbnailphoto" },
            @{  Desc = "Title-Jobtitle" ; From = $ADUser.Title ; To = $szJobtitle ; ADField = "title" }
        )

        # Test specific item update
        #$PropMap = @(
        #    @{  Desc = "CostCode" ; From = $ADUser.postofficebox ; To = $szCostCentre ; ADField = "postofficebox" }
        #)

        # Add attribs to get-aduser above!

        If ($false) { Set-Aduser -identity gills } # test set-aduser params

        ForEach ($item in $PropMap) {
            
            # Check if AD attrib is not null, multi valued and get first one
            if ($null -ne $item.from) {
                if ($item.from.GetType().name -eq "ADPropertyValueCollection") {
                    $from = $item.from[0].Trim() 
                    if ($from -eq "") { $from = $null}
                } else {
                    # String or byte
                    $from = $item.from
                }
                #if ($item.from.GetType().name -eq "String" ) {
                #    $from = $item.from 
                #}
            } else {
                $from = $null
            }

            # From null and to null => Do Nothing
            If(($null -eq $from) -and ($null -eq $item.to)){
                Write-SGLog ($szNTLogon + ": " + $Item.Desc + " Both Null") -Verbose $true
            }

            # From notnull and to null => Clear
            If(($null -ne $from) -and ($null -eq $item.to)){
                $Params = @{
                    Identity = $NTUser;
                    Clear = $item.ADField
                }
                #Set-ADUser @Params
                $Message = $szNTLogon + ": " + "Clear " + $Item.Desc + " as null"
                Write-SGLog -SGlogMessage $Message

                $ADChanges += [PSCustomObject]@{
                    NTUser = $NTUser
                    Type = "Clear"
                    Params = $Params
                    Message = $Message
                }
            } else {
                $Message = $szNTLogon + ": " + $Item.Desc + " already null"
                Write-SGLog -SGlogMessage $Message -Verbose $true
            }

            # From null and to notnull => Check and update
            If(($null -eq $from) -and ($null -ne $item.to)){
                $Params = @{
                    Identity = $NTUser;
                    Replace = @{$item.ADField = $item.To}
                }    
                #Set-ADUser @Params
                $StrTo = TrimString -String $item.To -StringLength 80
                $Message = $szNTLogon + ": " + "Change " + $Item.Desc + " From Null to " + [char]34 + $StrTo + [char]34
                Write-SGLog -SGlogMessage $Message

                $ADChanges += [PSCustomObject]@{
                    NTUser = $NTUser
                    Type = "Change"
                    Params = $Params
                    Message = $Message
                }
            } else {
                $Message = $szNTLogon + ": " + $Item.Desc + " already up to date"
                Write-SGLog -SGlogMessage $Message -Verbose $true
            }

            # From notnull and to notnull => Check and update
            If (($null -ne $from) -and ($null -ne $item.To)) {

                # Compare string or byte array
                $NeedToUpdate = -not(-not(Compare-Object $from $item.to -SyncWindow 0))

                if ($NeedToUpdate -or $ForceUpdate) {
                    $Params = @{
                        Identity = $NTUser;
                        Replace = @{$item.ADField = $item.To}
                    }    
                    #Set-ADUser @Params
                    $StrFrom = TrimString -String $from -StringLength 80
                    $StrTo = TrimString -String $item.To -StringLength 80
                    $Message = $szNTLogon + ": " + "Change " + $Item.Desc + " From " + [char]34 + $StrFrom + [char]34 + " to " + [char]34 + $StrTo + [char]34
                    Write-SGLog -SGlogMessage $Message

                    $ADChanges += [PSCustomObject]@{
                        NTUser = $NTUser
                        Type = "Change"
                        Params = $Params
                        Message = $Message
                    }
                } else { 
                    $Message = $szNTLogon + ": " + $Item.Desc + " already up to date"
                    Write-SGLog -SGlogMessage $Message -Verbose $true
                }
            }
        }
    }
}

$ADChanges | Out-GridView



# ===================================================
# Process Changes
# ===================================================

$message = ""

ForEach ($ADChange in $ADChanges) {
    $message += $ADChange.Message + "<br>"
    $Params = $ADChange.Params
    try {
        Set-ADUser @Params    
    }
    catch {
        Write-Host "Error setting AD attrib: " + $ADChange.Message
    }
}

# ===================================================
# Report and email
# ===================================================


if ($ADChanges.Count -gt 0) {

    $WhatIfPreference = $false
    $Message = "<html>" + $message + "</html>"
    #$Message | Out-File ".\Update-ADUserDetails.htm"

    $EmailSMTP = "smtp.moorfields.nhs.uk"
    $EmailFrom = "ADUpdate@moorfields.nhs.uk"
    $EmailTo = "moorfields.italerts@nhs.net"

    $rptDate=(Get-date)

    $messageParameters = @{ 
        Subject = "[CSD->AD Update sync on " + $rptDate.ToString($cultureENGB) + "]"
        Body = $global:Message
        From = $EmailFrom
        To = $EmailTo
        #Attachments = ".\Update-ADUserDetails.txt"
        SmtpServer = $EmailSMTP
    } 

    #Send-MailMessage @messageParameters -BodyAsHtml

}

Stop-Transcript
