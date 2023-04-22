# get NIC and HBA versions

$computers = @()

For ($i = 11; $i -le 18; $i++) {
    If ($i -lt 10) { $servername = "MEHVMC0" + $i.ToString() } else { $servername = "MEHVMC" + $i.ToString() }
    $Computers += $servername
}

<#
For ($i = 1; $i -le 16; $i++) {
    If ($i -lt 10) { $servername = "MEHVM-0" + $i.ToString() } else { $servername = "MEHVM-" + $i.ToString() }
    $Computers += $servername
}
#>

#$computers = "MEHVM15","MEHVM16","MEHVM17","MEHVM18"

$results = @()

$scriptblock = { Get-NetAdapter | where-object {$_.InterfaceDescription -like "*"} | Select-Object Name, InterfaceDescription,DriverVersion, DriverDate, DriverProvider }

$params = @{ 'ComputerName'=$computers;
            'ScriptBlock'=$scriptblock;
            'ArgumentList'=$path }

$results += Invoke-Command @params

$results | Out-GridView

# FC details

$objOutput = @()

foreach ($objComputer in $Computers) {

    $colHBA = Get-WmiObject -Class MSFC_FCAdapterHBAAttributes -Namespace root\WMI -ComputerName $objComputer -ErrorAction Stop

    foreach ($objHBA in $colHBA) {

        $objDeets = [PSCustomObject] @{

            "Computername" = $objComputer
            "Node WWN" = (($objHBA.NodeWWN) | ForEach-Object {"{0:X2}" -f $_}) -join ":"
            "Model" = $objHba.Model
            "Model Description" = $objHBA.ModelDescription
            "Driver Version" = $objHBA.DriverVersion
            "Firmware Version" = $objHBA.FirmwareVersion
            "Active" = $objHBA.Active
        }

    $objOutput += $objDeets
    }
}
$objOutput | Out-GridView

