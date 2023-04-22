###Configure parameters
[CmdletBinding()]
param (
    [int]$TPMminVer = 1.2,
    [int]$DirectxVer = 12,
    [int]$WDDMVer = 2.0
)
###Disable IE first run
$keyPath = 'Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main'
if (!(Test-Path $keyPath)) { New-Item $keyPath -Force | Out-Null }
Set-ItemProperty -Path $keyPath -Name "DisableFirstRunCustomize" -Value 1
###Generate CSV from Microsoft approved processor list
$URI = "https://docs.microsoft.com/en-us/windows-hardware/design/minimum/supported/windows-11-supported-intel-processors","https://docs.microsoft.com/en-us/windows-hardware/design/minimum/supported/windows-11-supported-amd-processors","https://docs.microsoft.com/en-us/windows-hardware/design/minimum/supported/windows-11-supported-qualcomm-processors"
$table = @()
$proc =  Get-CimInstance -class CIM_Processor | Select-Object Name
foreach($Address in $URI){
    $Result = Invoke-WebRequest $Address
    $data = ($Result.ParsedHtml.getElementsByTagName("table") | Select-Object -First 1).rows
    forEach($row in $data){
        if($row.tagName -eq "tr"){
            $thisRow = @()
            $cells = $row.children
            forEach($cell in $cells){
            if($cell.tagName -imatch "t[dh]"){
                    $thisRow += $cell.innerText
                }
            }
            $table += $thisRow -join ","
        }
    }
}
$final = $table | ConvertFrom-Csv -Delimiter ","
$ProcCompatible = $false
foreach($cpu in $final.model){
    
    if($proc.name -like "*" + $cpu + "*"){
        $ProcCompatible = $true
        break
    }
}
###Get Procossor
$proc =  Get-CimInstance -class CIM_Processor | Select-Object Name
$ProcCompatible = $false
###Compare processor to approved list
foreach($cpu in $final.model){
    
    if($proc.name -like "*" + $cpu + "*"){
        $ProcCompatible = $true
        break
    }
}
###Test TPM
$TPMCompatible = $false
Try{$GetTPM = (Get-tpm).TPMPresent}
Catch{}
If($GetTPM -eq $true){
    $TPMVer = Get-CimInstance -Namespace "root/cimv2/Security/MicrosoftTPM" -ClassName win32_tpm | Select-Object specversion
    If($TPMVer.specversion.Split(',')[0] -ge $TPMminVer){
        $TPMCompatible = $true
    }
}
###Test UEFI
$UEFICompatible = $false
Try {$UEFI = Confirm-SecureBootUEFI}
Catch{}
If($UEFI){
    $UEFICompatible = $True
}
###Test Direct X 12
Start-Process -FilePath "C:\Windows\System32\dxdiag.exe" -ArgumentList "/dontskip /whql:off /t C:\dxdiag.txt" -Wait
###Load File into file stream
$file = New-Object System.IO.StreamReader -ArgumentList "C:\dxdiag.txt"
###Setting initial variable state
$Directx12Compatible = $false
$WDDMCompatible = $false
###Reading file line by line
try {
    while ($null -ne ($line = $file.ReadLine())) {
###Mark start of applied policies
        if ($line.contains("DDI Version:") -eq $True) {
            if($line.Trim("DDI Version: ") -ge $DirectxVer){
                $Directx12Compatible = $true
            }
        }
        elseif ($line.contains("Driver Model:") -eq $True) {
            if($line.Trim("Driver Model: WDDM ") -ge $WDDMVer){
                $WDDMCompatible = $true
            }
        }
    }
}
finally {
    $file.Close()
    Remove-Item "C:\dxdiag.txt" -Force
}
[pscustomobject]@{
    Processor = $ProcCompatible
    TPM = $TPMCompatible
    UEFI = $UEFICompatible
    Directx12 = $Directx12Compatible
    WDDM = $WDDMCompatible 
}
# SIG # Begin signature block
# MIIOyQYJKoZIhvcNAQcCoIIOujCCDrYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTG0oK7NfVGqQIiiEsCB5TdPQ
# Uq2gggyHMIIEnjCCA4agAwIBAgITKwAJd8is0KEeNtA2AwADAAl3yDANBgkqhkiG
# 9w0BAQsFADB0MRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/IsZAEZFgNu
# aHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMS0wKwYDVQQDEyRNb29yZmll
# bGRzIEV5ZSBIb3NwaXRhbCBJc3N1aW5nIENBIDEwHhcNMjExMTIyMTY0NTE2WhcN
# MjIxMTIyMTY0NTE2WjBnMRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/Is
# ZAEZFgNuaHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMQ4wDAYDVQQDEwVV
# c2VyczEQMA4GA1UEAxMHQURNSU5TRzCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkC
# gYEApUscCZHWG6rrOiPR/Wn2Oe1OkHjaQ/J//miTNefzWgO3mrcqYklJC1dKme+G
# +HGjfDOcyvZVXBdIDvUSSHHwu6D/F3lO713P6Gj6x/4E3b4G0hKpUMav2SaRzhSi
# AywbZPesJAJb6+t09bYWFo112nI4hwMLs7JOktxziG4NmX0CAwEAAaOCAbgwggG0
# MCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBnMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDA1BgNVHREELjAsoCoGCisGAQQBgjcU
# AgOgHAwaYWRtaW4uc2dAbW9vcmZpZWxkcy5uaHMudWswHQYDVR0OBBYEFOw+8mlj
# ynFEbBoTjL2Ju3TaAa8/MB8GA1UdIwQYMBaAFEhLXjg47Bv4/Y3dPjV0XECB/iLm
# MGQGA1UdHwRdMFswWaBXoFWGU2h0dHA6Ly9jcmwubW9vcmZpZWxkcy5uaHMudWsv
# cGtpL01vb3JmaWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMElzc3VpbmclMjBDQSUy
# MDEuY3JsMIGLBggrBgEFBQcBAQR/MH0wewYIKwYBBQUHMAKGb2h0dHA6Ly9jcmwu
# bW9vcmZpZWxkcy5uaHMudWsvcGtpL01FSENBMS5tb29yZmllbGRzLm5ocy51a19N
# b29yZmllbGRzJTIwRXllJTIwSG9zcGl0YWwlMjBJc3N1aW5nJTIwQ0ElMjAxKDMp
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEAD32i9R8H6rGtJYuXT//TTtIZcmu3QuGW
# 1JKPVD1YvNbX7HBEwilUa5Tkjy8gbFE6nvTSoIBUC9Jx76HvL8CnOpFZjeGDjRrJ
# QVWiL1MgRb3Tx0+TsBmZQCtUEqIubx84nFJggEZ+gi3hNVhdYtdwim4Grp1WFlIa
# h+ZD/UaY34cqJT5Ts4A0UpqLIvtFmwcxrYaC7G2k9i861mKTRoTSI0QceBT9C3Z5
# DCnBKH6wPRT6hDFHylEKcrOyibcgjK6OUqhoEUEZGmSnADhuJ9WIDz3jl8ElvZMV
# FmN3E4/yPTnX9FrS1W2PPEYnpFnw88NNWHZNikHcjnSaeXoTE0D8czCCB+EwggXJ
# oAMCAQICE1oAAAFrHippo1wMt9IAAwAAAWswDQYJKoZIhvcNAQELBQAwbzESMBAG
# CgmSJomT8ixkARkWAnVrMRMwEQYKCZImiZPyLGQBGRYDbmhzMRowGAYKCZImiZPy
# LGQBGRYKbW9vcmZpZWxkczEoMCYGA1UEAxMfTW9vcmZpZWxkcyBFeWUgSG9zcGl0
# YWwgUm9vdCBDQTAeFw0yMDEwMjAxNDAxMzdaFw0yODEwMjAxNDExMzdaMHQxEjAQ
# BgoJkiaJk/IsZAEZFgJ1azETMBEGCgmSJomT8ixkARkWA25oczEaMBgGCgmSJomT
# 8ixkARkWCm1vb3JmaWVsZHMxLTArBgNVBAMTJE1vb3JmaWVsZHMgRXllIEhvc3Bp
# dGFsIElzc3VpbmcgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AMFV6/y5fa7Si0xlLPcLDQNhaiwDZTwpZOeUVY7W7VGj4kiFr8K/AjYWEGKcvgSW
# p/xyBKfDo9FtA3Szov46uwY4YzJ/pKAiCPRhIVeLxuGK9UHuYLk65Gg0kRhFUSY+
# gr9ok1MCpAqjgsGmyjqtFzSBQj2zKQo6prAV5E++0oi9kVoTJl/oyqMqRvm3vmG8
# 3CgO3gEs1YF2dl15bKXLnD9llZ021/biUTn90zfWT7pExTG6n1hOUTQlVwCEplPO
# b6kiGiAwVwSL7f/Czh/QhmCLLEoLnucbRwUkmukri4vcbElTYAXv6PthXSvTSo0T
# Vn1jSCKqLl3f8yvNB2RV3tsCAwEAAaOCA28wggNrMBAGCSsGAQQBgjcVAQQDAgED
# MCMGCSsGAQQBgjcVAgQWBBQBF6Mc6SWh+ffiSl05W9Eugo56JjAdBgNVHQ4EFgQU
# SEteODjsG/j9jd0+NXRcQIH+IuYwEQYDVR0gBAowCDAGBgRVHSAAMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFBEgsbQZNLK+r6C+p4wdzwFxWR3XMIIBQwYDVR0fBIIBOjCC
# ATYwggEyoIIBLqCCASqGgdlsZGFwOi8vL0NOPU1vb3JmaWVsZHMlMjBFeWUlMjBI
# b3NwaXRhbCUyMFJvb3QlMjBDQSxDTj1NRUhDQVJPT1QsQ049Q0RQLENOPVB1Ymxp
# YyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24s
# REM9bW9vcmZpZWxkcyxEQz1uaHMsREM9dWs/Y2VydGlmaWNhdGVSZXZvY2F0aW9u
# TGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hkxodHRw
# Oi8vY3JsLm1vb3JmaWVsZHMubmhzLnVrL3BraS9Nb29yZmllbGRzJTIwRXllJTIw
# SG9zcGl0YWwlMjBSb290JTIwQ0EuY3JsMIIBXQYIKwYBBQUHAQEEggFPMIIBSzCB
# zwYIKwYBBQUHMAKGgcJsZGFwOi8vL0NOPU1vb3JmaWVsZHMlMjBFeWUlMjBIb3Nw
# aXRhbCUyMFJvb3QlMjBDQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2Vydmlj
# ZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1tb29yZmllbGRzLERD
# PW5ocyxEQz11az9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlm
# aWNhdGlvbkF1dGhvcml0eTB3BggrBgEFBQcwAoZraHR0cDovL2NybC5tb29yZmll
# bGRzLm5ocy51ay9wa2kvTUVIQ0FST09ULm1vb3JmaWVsZHMubmhzLnVrX01vb3Jm
# aWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBDQSgzKS5jcnQwDQYJKoZI
# hvcNAQELBQADggIBAJSA/NapMf4IvqWSbqO4nZYjGx2WPIavlNGyT51MohUuN2dp
# yqf0dSwKFC1H+xhqKJLRKotJNcsms/qVl1XK+y69+p6NbKda5iQwty7S3BrwYhwb
# jkswcemghyEkliHDcc7swiNusSJJA23zAMtbgA0c+ea3OPhD+lf80su6Pimr0jP/
# E0HO+hs5pOzwoPVFmlkaB69kYLcK98xkY58iqFpheD6gnDpjpQlGArWJ4+dvFBNF
# W0dnnrRq1ZEJEMmQSUFFDeGeffIzdtUyNr1vUTbKBRL1cFLgnZf8BavBI14ah/8f
# QwL4rP9AmZelmgFUvdP+oiquL6oZgiAm3Ryc5xZ6M2iIeGZHqeebfhcuA4YIsCXy
# c/VQSE3i6YGYKgrWFtJAGKay2578sUzNV5/DPYdgHbT9p4kaP/4VDFRpWYSCu7RY
# AqBqz8njQTNjmLgAG+HCvuRzqF6vd9rAzP/sndyyqq2DKdlv+x7XebHtJcr6RDZ5
# D8KqoeC2SAv7FiLu0/1tgdCj6gPGr7tcQmwGEeU+VijtwRsQ5FYHODjZSE3C713G
# VGJuIkg7WrnCxSYpmDajaOnIDmFS4VRJNN2pZttBlTyrd0dcYTPhvZNvPcS5UCIX
# Sy0k3YVReHUFhNM7hdqQJJajSs3+DmhemhKsUoRd+FF5nMXF61WC4EfakNhEMYIB
# rDCCAagCAQEwgYswdDESMBAGCgmSJomT8ixkARkWAnVrMRMwEQYKCZImiZPyLGQB
# GRYDbmhzMRowGAYKCZImiZPyLGQBGRYKbW9vcmZpZWxkczEtMCsGA1UEAxMkTW9v
# cmZpZWxkcyBFeWUgSG9zcGl0YWwgSXNzdWluZyBDQSAxAhMrAAl3yKzQoR420DYD
# AAMACXfIMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSO4JR4XkfkQuMCq3VYWMmBUOmybDANBgkq
# hkiG9w0BAQEFAASBgAJikDk9F4KY+M8i22+4q/TjwX0KBqFxfL7OUFQNGlM/vkz6
# JKfWPFNQQRILZOrr1whXEACPVi4IX8Tc4ofwbyJEID/GHbkTfg3HeJ8e6qc2SFk9
# Y+3Vu8iO4xWsvEgoErskvbwwRywcjPxtKMZpJG0heS28/RINCoRREQ4VHjgw
# SIG # End signature block
