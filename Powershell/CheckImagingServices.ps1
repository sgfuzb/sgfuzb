$whatifpreference = $false

$servicelist = @( 
    @{Computername="M016815"; ServiceName="AdobeARMservice"},
    @{Computername="MEHIMAGENET6"; ServiceName="Tomcat7"},
    @{Computername="MEHHEYEX"; ServiceName="HELICSVC"},
    @{Computername="MEHEYESUITE"; ServiceName="mysql"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="Nil Dicom Service"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosDataGateway"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosImageExportService"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosImageProcessing"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosTableManagerService"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosTaskScheduler"},
    @{Computername="MEHOPTOS-CALI"; ServiceName="OptosMongoDB"},
    @{Computername="MEHFORUM"; ServiceName="CZM Advanced Data Export Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Database-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-EQW-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Glaucoma-Workplace-Analysis-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Glaucoma-Workplace-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Image-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Retina-Analysis-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Retina-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Server-Service"},
    @{Computername="MEHFORUM"; ServiceName="CZM-Worklist-Service"},
    @{Computername="MEHFORUM"; ServiceName="DICOM Gateway 2.1.4"}
)

$Message = "<br>"
$Message += "===================================================<br>"
$Message += "Imaging Server Service Status <br><br>"
$Message += "===================================================<br>"


#$services = $servicelist | %{Get-Service -Computername $_.Computername -ServiceName $_.ServiceName}
#$services

$Message += "<br>"

# loop through each service, if its not running, start it
foreach($Service in $servicelist)
{
    try {
        $arrService = Get-Service -Computername $service.Computername -ServiceName $service.ServiceName

        $Message += $arrService.status.ToString() + "`t" + $service.Computername + "`t" + $service.ServiceName + "`t" + $arrService.StartType + "<br>"

        Write-host $arrService.status "`t" $service.Computername "`t" $service.ServiceName "`t" $arrService.StartType

        if ($arrService.StartType -ne "Disabled") {
            while ($arrService.Status -ne 'Running')
            {
                
                $arrService.Start()
                $Message += ">>Starting Service..."+ "<br>"
                Start-Sleep -seconds 5
                $arrService.Refresh()
                if ($arrService.Status -eq 'Running')
                {
                    $Message += ">>Service is now Running"+ "<br>"
                }
            }
        } else {
            $Message += $arrService.status + "`t" + $service.Computername + "`t" + $service.ServiceName + "`t" + $arrService.StartType + "<br>"
            Write-host $arrService.status "`t" $service.Computername "`t" $service.ServiceName "`t" $arrService.StartType

            $Message += ">>Service is disabled"+ "<br>"
            Write-host ">>Service is disabled"
        }
    } catch { 
        $Message += ">>Service cannot be connected to / does not exist" + "<br>"
        Write-host ">>Service cannot be connected to / does not exist"
    }
}

$Message +=  "DONE!!" + "<br>"

#Settings for Email Message
$rptDate=(Get-date)
if ($whatifpreference -eq 1) {
    $subjectprefix = "###TEST### " 
    $Message
} else {$subjectprefix = "" } 

$messageParameters = @{ 
    Subject = "[" + $subjectprefix + "Imaging Server Service Status " + $rptDate.ToString($cultureENGB) + "]"
    Body = $Message
    From = "it.alerts@moorfields.nhs.uk" 
    To = "moorfields.italerts@nhs.net", "vikash@nhs.net"
    #To = "sg@nhs.net"
    SmtpServer = "smtp.moorfields.nhs.uk"
    #SmtpServer = "127.0.0.1"
} 
#Send Report Email Message
Send-MailMessage @messageParameters -BodyAsHtml
