﻿#Script to find if NHS Mail profile has been created and if so, remove and allow Group Policy to re-add without user intervention.

#Allow running of unsigned scripts from network locations
Set-ExecutionPolicy bypass -Force

$Log="The following profiles have been removed:`n"

#Test to see whether or not an OST file has been created in the last few hours - if so, profile has been created and partially populated 
if (Get-ChildItem C:\users\$env:username\appdata\local\microsoft\outlook\ -recurse -include @("*.ost") | Where-Object { $_.CreationTime -gt (get-date).addhours(-5) })
{
    #Check to ensure profile was definitely created

    if(Test-Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\NHS_mail')
        {
        #Remove Outlook 2010 profile
        Remove-Item 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\NHS_mail' -Recurse -Force
        $log+="`n Outlook 2010 Removed"
        }

    #Check to ensure profile was defintely created

    if(Test-Path 'HKCU:\Software\Microsoft\Office\15.0\Outlook\Profiles\NHS_mail')
        {
        #Remove Office 2013 profile
        Remove-Item 'HKCU:\Software\Microsoft\Office\15.0\Outlook\Profiles\NHS_mail' 
        $log+="`n Outlook 2013 Removed"
        }

    #Check to ensure profile was definitely created

    if(Test-Path 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\NHS_mail')
        {
        #Remove Office 2016 profile
        Remove-Item 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\NHS_mail' -Recurse -Force
        $log+="`n Outlook 2016 Removed"
        }

else {($log = "NHS Net GPO doesn't appear to have run. Please call the helpdesk to ensure you've migrated successfully.")}

}

#If GPO hasn't run, run the credential manager logon script and a GPUpdate /Force

write-host $Log

write-host "`n Reconfiguring Outlook profiles and setting up Credential Manager"

start-process "\\moorfields.nhs.uk\sysvol\moorfields.nhs.uk\Policies\{4CD74FE0-ACF4-4905-922C-2A2591867B15}\User\Scripts\Logon\NHSmailLogon.bat" -NoNewWindow -Wait

[string]$credtest = cmdkey /list:autodiscover.nhs.net

if ($credtest -match "NONE") {
$log2 = "`n Credential Manager population Failed"
}
else {$log2 = "`n Credential Manager population Success"
}

gpupdate /force

$key1 = Test-Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles\NHS_mail'
$Key2 = Test-Path 'HKCU:\Software\Microsoft\Office\15.0\Outlook\Profiles\NHS_mail'
$Key3 = Test-Path 'HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles\NHS_mail'

if (($key1 -eq $true -and $key2 -eq $true -and $key3 -eq $true)) {

$log2+= "`n Registry keys added successfully"}
Else {$log2+= "Registry keys did not repopulate correctly"
}

#Show the log to the user

Write-Host $log2

#Write the log to Appdata for IT review if necessary

$Output = $log + "`r`n" + $log2 | Out-File "$env:appdata\gpodebug.txt"

Read-Host "Press enter to log off and then please log back on"

logoff
# SIG # Begin signature block
# MIIOtwYJKoZIhvcNAQcCoIIOqDCCDqQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmykhUmN6pqDWJeCB7fnpWv5M
# Jg+gggx1MIIEnzCCA4egAwIBAgITJAABTKSjGyzMK9bjcwABAAFMpDANBgkqhkiG
# 9w0BAQUFADB0MRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/IsZAEZFgNu
# aHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMS0wKwYDVQQDEyRNb29yZmll
# bGRzIEV5ZSBIb3NwaXRhbCBJc3N1aW5nIENBIDIwHhcNMTcxMjEzMTEwNjQwWhcN
# MTgxMjEzMTEwNjQwWjBlMRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/Is
# ZAEZFgNuaHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMQ4wDAYDVQQDEwVV
# c2VyczEOMAwGA1UEAxMFR0lMTFMwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGB
# AMMRSef/Vfbp0g4OWrXRF8hJ33bLZv2fhujJWsGHYK6MhV97IJVWdkk39PsC4UUk
# VbISCoXcvZQcYsl2TFB5LvU0CLlGDeme0j5PH+b7tLk6WIRdFuNROeVXUl2yot5v
# uqfz7I/ipgKnTGIGcq4EOVOlgfSrXenPL3M+rwpa7HGdAgMBAAGjggG7MIIBtzAl
# BgkrBgEEAYI3FAIEGB4WAEMAbwBkAGUAUwBpAGcAbgBpAG4AZzATBgNVHSUEDDAK
# BggrBgEFBQcDAzALBgNVHQ8EBAMCB4AwHQYDVR0OBBYEFDeNOn2SeYjIvpwyg5lq
# A6WBDImZMB8GA1UdIwQYMBaAFCiOb2Fkkjn/OiuqJ6DeARK856JpMGQGA1UdHwRd
# MFswWaBXoFWGU2h0dHA6Ly9jcmwubW9vcmZpZWxkcy5uaHMudWsvcGtpL01vb3Jm
# aWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMElzc3VpbmclMjBDQSUyMDIuY3JsMIGL
# BggrBgEFBQcBAQR/MH0wewYIKwYBBQUHMAKGb2h0dHA6Ly9jcmwubW9vcmZpZWxk
# cy5uaHMudWsvcGtpL01FSENBMi5tb29yZmllbGRzLm5ocy51a19Nb29yZmllbGRz
# JTIwRXllJTIwSG9zcGl0YWwlMjBJc3N1aW5nJTIwQ0ElMjAyKDEpLmNydDA4BgNV
# HREEMTAvoC0GCisGAQQBgjcUAgOgHwwdU3RldmVuLkdpbGxAbW9vcmZpZWxkcy5u
# aHMudWswDQYJKoZIhvcNAQEFBQADggEBADxFpBxkWjdYHuJwGFjs4VFIO32ZVa56
# LpubvGmu7XsltOyqj8fpNWv1i4EazCqQlEoQEiIekfR7BgDtpSODkq0zpk7stEUR
# ajNVV4AMPjI0aQxUWxHcRRWw014MT9/RSOsfI3asR++tG0I8MCxxylLB4vefyTnu
# zpq/t9RykXiM0DMZ6g8EKI45TLniryrffz57U3PlTK3JmKVWcwUSpJjZwBiaibbD
# UlLxdXda1NLYKor8TmFhyJWSbwy+rJ34AAj2v+vrAyctiCq+ZeV+p7aYz3ag41AK
# 4PNo6TC+OhrZfT88LIuxz6Z6yrsVK/pwhqM9Biqje3prNHqJp2Q5WLwwggfOMIIF
# tqADAgECAhNaAAAAHq/ClPtZdEQEAAIAAAAeMA0GCSqGSIb3DQEBBQUAMG8xEjAQ
# BgoJkiaJk/IsZAEZFgJ1azETMBEGCgmSJomT8ixkARkWA25oczEaMBgGCgmSJomT
# 8ixkARkWCm1vb3JmaWVsZHMxKDAmBgNVBAMTH01vb3JmaWVsZHMgRXllIEhvc3Bp
# dGFsIFJvb3QgQ0EwHhcNMTMxMjAyMTAyNDMwWhcNMjExMjAyMTAzNDMwWjB0MRIw
# EAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/IsZAEZFgNuaHMxGjAYBgoJkiaJ
# k/IsZAEZFgptb29yZmllbGRzMS0wKwYDVQQDEyRNb29yZmllbGRzIEV5ZSBIb3Nw
# aXRhbCBJc3N1aW5nIENBIDIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC0AEWBbWJGelA9/K/lejjQThTfCXJNgic2pUooZD2GyLUGF9F0z+ehONZqL+tA
# Jhvcxp1r6t7Lzd9/ZoKqgd9k5yZrJVyYWgilotfV1f68CgwtjVgewsWGU7qqeSwU
# t+URw81RkcDRu88k0GWpXLDnYxqkRVzd105h84HxRuq7ArLMIj2jE4XqSHhMnsTS
# r45gWxnqWjNpt64CckfhS8QUTlvmiMNxsdowE3DqczQmqAQBfBpEf/hBk+I8iCn5
# F+86lf4IfZw4/Qhhxm8y9pWgVo/jbjv691RdgaeseAP8smFNRTaJ5s8qqJxYe+b1
# a3a1tEQqWcUDKfbON4+5Sot9AgMBAAGjggNcMIIDWDAQBgkrBgEEAYI3FQEEAwIB
# ATAjBgkrBgEEAYI3FQIEFgQUDrzAKAaT52EDzzeKsAqSgsBYFhowHQYDVR0OBBYE
# FCiOb2Fkkjn/OiuqJ6DeARK856JpMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
# MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFBEgsbQZ
# NLK+r6C+p4wdzwFxWR3XMIIBQwYDVR0fBIIBOjCCATYwggEyoIIBLqCCASqGgdls
# ZGFwOi8vL0NOPU1vb3JmaWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBD
# QSxDTj1NRUhDQVJPT1QsQ049Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2Vz
# LENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9bW9vcmZpZWxkcyxEQz1u
# aHMsREM9dWs/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50hkxodHRwOi8vY3JsLm1vb3JmaWVsZHMu
# bmhzLnVrL3BraS9Nb29yZmllbGRzJTIwRXllJTIwSG9zcGl0YWwlMjBSb290JTIw
# Q0EuY3JsMIIBXQYIKwYBBQUHAQEEggFPMIIBSzCBzwYIKwYBBQUHMAKGgcJsZGFw
# Oi8vL0NOPU1vb3JmaWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBDQSxD
# Tj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049
# Q29uZmlndXJhdGlvbixEQz1tb29yZmllbGRzLERDPW5ocyxEQz11az9jQUNlcnRp
# ZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTB3
# BggrBgEFBQcwAoZraHR0cDovL2NybC5tb29yZmllbGRzLm5ocy51ay9wa2kvTUVI
# Q0FST09ULm1vb3JmaWVsZHMubmhzLnVrX01vb3JmaWVsZHMlMjBFeWUlMjBIb3Nw
# aXRhbCUyMFJvb3QlMjBDQSgyKS5jcnQwDQYJKoZIhvcNAQEFBQADggIBABrJ4wy+
# jZWmEzY6O+MtxCFrALOErqbVmI7WnpcqTwedyI8BjpCljApwy1ljwR5b1Ann6CQa
# 4zlezwrPeVURK9XSm4cZVMHzqOK97sR8RyO/74atrUsKIa4pfbNVcIdEQo80DOPt
# P2qO/EDO0SgsmhHCukdHR0SUNO9jryG0vmkKISKV5hLLlnDzy4p9zQykwoyg4dWK
# 0A//jCEsOlud/KqyaV+jY4RNoQcwjSko7dzvYzAKZaN9LMW3K4ztXrjD/d9HD7qR
# mTjiX2g99pBK09VDQzk95ZD/tBQ7KgHlOYXkE4PErFVYT/BGhQplWXrLGFqkXANA
# 9u57zimVbzPYBfPDAZkzleqO5Sum6KoduNLiMEQqFoK9AYLOnOv7rT1yCeW5B/XK
# kPEvJvJrwpuYrJL68xDoEGP+qSV8Pe+++RqV4i/RpnHeRyf4ik+OpbPjGF+otB7/
# tiE+shm9dzEZhv5narIP/7kogkndu2eYzTkk3MokM7k1UUP5iS1u5qtu1yBIFbNm
# wBhZzR2p2hDPKn3IXSa2rt5OX7AitGCNrukYT/M9vje0F7bm8TAgX+X6ScvgFAk1
# GatNpT1cbx0Cn0bv9tazEn/nT+bD9nWqPkjaSCaPQxWQknAY5jm6DQ/DJBazs7tM
# J7l1wzRfT9kaY9zFKcep3QgnN1whiNIY4IW1MYIBrDCCAagCAQEwgYswdDESMBAG
# CgmSJomT8ixkARkWAnVrMRMwEQYKCZImiZPyLGQBGRYDbmhzMRowGAYKCZImiZPy
# LGQBGRYKbW9vcmZpZWxkczEtMCsGA1UEAxMkTW9vcmZpZWxkcyBFeWUgSG9zcGl0
# YWwgSXNzdWluZyBDQSAyAhMkAAFMpKMbLMwr1uNzAAEAAUykMAkGBSsOAwIaBQCg
# eDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJ
# BDEWBBR01w6j+Irkwo7ydUkOf1nS06ZlfjANBgkqhkiG9w0BAQEFAASBgKQOaqgv
# hICKpX6bhM30JLc52cb2YS6GbFtcbmY0FjLec2TChw70OU7pl7np4XKXWP2dw12v
# EUxsMfSZYBLP+LYYLh6B3jQ8vie2ws6vITP43hBNkry/o86djmFk9XX6CFIfP4il
# 5IC1eYrEkaS0AkQSx5tZ5COPcUjhY1+WJJmf
# SIG # End signature block
