# Regex pattern for SIDs
$PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
 
# Get Username, SID, and location of ntuser.dat for all users
$ProfileList = gp 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} | 
    Select  @{name="SID";expression={$_.PSChildName}}, 
            @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}}, 
            @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
 
# Get all user SIDs found in HKEY_USERS (ntuder.dat files that are loaded)
$LoadedHives = gci Registry::HKEY_USERS | ? {$_.PSChildname -match $PatternSID} | Select @{name="SID";expression={$_.PSChildName}}
 
# Get all users that are not currently logged
$UnloadedHives = Compare-Object $ProfileList.SID $LoadedHives.SID | Select @{name="SID";expression={$_.InputObject}}, UserHive, Username
 
# Loop through each profile on the machine
Foreach ($item in $ProfileList) {
    # Load User ntuser.dat if it's not already loaded
    IF ($item.SID -in $UnloadedHives.SID) {
        reg load HKU\$($Item.SID) $($Item.UserHive) | Out-Null
    }
 
    #####################################################################
    # This is where you can read/modify a users portion of the registry 
 
    # This example lists the Uninstall keys for each user registry hive
    "{0}" -f $($item.Username) | Write-Output
    
    Remove-Item -Path "registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\Teams" -Recurse -ErrorAction SilentlyContinue
    

    #Get-ItemProperty registry::HKEY_USERS\$($Item.SID)\Software\Microsoft\Office\Teams\PreventInstallationFromMsi | Foreach {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}
    #Get-ItemProperty registry::HKEY_USERS\$($Item.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Foreach {"{0} {1}" -f "   Program:", $($_.DisplayName) | Write-Output}
    
    #####################################################################
 
    # Unload ntuser.dat        
    IF ($item.SID -in $UnloadedHives.SID) {
        ### Garbage collection and closing of ntuser.dat ###
        [gc]::Collect()
        reg unload HKU\$($Item.SID) | Out-Null
    }
}

# Remove teams files in profiles
$users = Get-ChildItem c:\users | ?{ $_.PSIsContainer }
foreach ($user in $users){
    $userpath = "C:\Users\$user\AppData\Local\Microsoft\Teams"
    Try{
        Remove-Item $userpath\* -Recurse -ErrorVariable errs -ErrorAction SilentlyContinue  
    } 
    catch {
        "$errs" | Out-File c:\temp\errors.txt -append
    }
}

# SIG # Begin signature block
# MIIeCAYJKoZIhvcNAQcCoIId+TCCHfUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYWO6LMsa6+phEX0fD5F5bTS7
# jTKgghmzMIIEnjCCA4agAwIBAgITKwAId68+pK4Xsi1ECwACAAh3rzANBgkqhkiG
# 9w0BAQUFADB0MRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/IsZAEZFgNu
# aHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMS0wKwYDVQQDEyRNb29yZmll
# bGRzIEV5ZSBIb3NwaXRhbCBJc3N1aW5nIENBIDEwHhcNMTkxMDA3MTI1NDAxWhcN
# MjAxMDA2MTI1NDAxWjBnMRIwEAYKCZImiZPyLGQBGRYCdWsxEzARBgoJkiaJk/Is
# ZAEZFgNuaHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRzMQ4wDAYDVQQDEwVV
# c2VyczEQMA4GA1UEAxMHQURNSU5TRzCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkC
# gYEAp6obGxWtX7CfhR1ab0miTUMJ3dJSAcIFzFe8M8/QQJBkMpmjmQjP1a0MtiLP
# fxFyEUz23Q/luCOFw2kew8kltEHHaCT4sb4DiWSwarySsFpsIRbbixB3xZnBalNI
# AnZnOKyoMpEwxU2E+2dvYKbGlkRNlRhgNNscd7bKtZzXr50CAwEAAaOCAbgwggG0
# MCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBnMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDA1BgNVHREELjAsoCoGCisGAQQBgjcU
# AgOgHAwaYWRtaW4uc2dAbW9vcmZpZWxkcy5uaHMudWswHQYDVR0OBBYEFOw+kKjw
# EW7kBkBemFdlrcZVrZtbMB8GA1UdIwQYMBaAFEhLXjg47Bv4/Y3dPjV0XECB/iLm
# MGQGA1UdHwRdMFswWaBXoFWGU2h0dHA6Ly9jcmwubW9vcmZpZWxkcy5uaHMudWsv
# cGtpL01vb3JmaWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMElzc3VpbmclMjBDQSUy
# MDEuY3JsMIGLBggrBgEFBQcBAQR/MH0wewYIKwYBBQUHMAKGb2h0dHA6Ly9jcmwu
# bW9vcmZpZWxkcy5uaHMudWsvcGtpL01FSENBMS5tb29yZmllbGRzLm5ocy51a19N
# b29yZmllbGRzJTIwRXllJTIwSG9zcGl0YWwlMjBJc3N1aW5nJTIwQ0ElMjAxKDIp
# LmNydDANBgkqhkiG9w0BAQUFAAOCAQEAMt+PtEY1oJ8DWsH4VIwqDOEZQs6zQmEM
# T4yaTGZecNiL+u+Ptqs4LV2grf6QlQGgHMOP30+PejlDp0Tinx5CQiMy/BMRlrso
# zp9mRYr9f8x7tt+FOIlENCLCc1Md3ofsIX4QdSfRwbf57uFN0qJ4pTS7/8HqAAnM
# YX47uH/VnNflSxZl911XN//d/Owt+7zHSXUpYm47MWu2e/1RKnmLJJZnv8m5Ktiy
# werMSxCoPcVhJjxTVMAd3NtK1rNBO4yLI/K2Zgu25Vses3QsrZCLDGywAQhCgI4M
# mw4oX+1kzWcBf1AXtU1TPAkqffq4pbTforA1aFlx2X8ySupvTXHCjzCCBmowggVS
# oAMCAQICEAMBmgI6/1ixa9bV6uYX8GYwDQYJKoZIhvcNAQEFBQAwYjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xMB4XDTE0
# MTAyMjAwMDAwMFoXDTI0MTAyMjAwMDAwMFowRzELMAkGA1UEBhMCVVMxETAPBgNV
# BAoTCERpZ2lDZXJ0MSUwIwYDVQQDExxEaWdpQ2VydCBUaW1lc3RhbXAgUmVzcG9u
# ZGVyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo2Rd/Hyz4II14OD2
# xirmSXU7zG7gU6mfH2RZ5nxrf2uMnVX4kuOe1VpjWwJJUNmDzm9m7t3LhelfpfnU
# h3SIRDsZyeX1kZ/GFDmsJOqoSyyRicxeKPRktlC39RKzc5YKZ6O+YZ+u8/0SeHUO
# plsU/UUjjoZEVX0YhgWMVYd5SEb3yg6Np95OX+Koti1ZAmGIYXIYaLm4fO7m5zQv
# MXeBMB+7NgGN7yfj95rwTDFkjePr+hmHqH7P7IwMNlt6wXq4eMfJBi5GEMiN6ARg
# 27xzdPpO2P6qQPGyznBGg+naQKFZOtkVCVeZVjCT88lhzNAIzGvsYkKRrALA76Tw
# iRGPdwIDAQABo4IDNTCCAzEwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAw
# FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwggG/BgNVHSAEggG2MIIBsjCCAaEGCWCG
# SAGG/WwHATCCAZIwKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNv
# bS9DUFMwggFkBggrBgEFBQcCAjCCAVYeggFSAEEAbgB5ACAAdQBzAGUAIABvAGYA
# IAB0AGgAaQBzACAAQwBlAHIAdABpAGYAaQBjAGEAdABlACAAYwBvAG4AcwB0AGkA
# dAB1AHQAZQBzACAAYQBjAGMAZQBwAHQAYQBuAGMAZQAgAG8AZgAgAHQAaABlACAA
# RABpAGcAaQBDAGUAcgB0ACAAQwBQAC8AQwBQAFMAIABhAG4AZAAgAHQAaABlACAA
# UgBlAGwAeQBpAG4AZwAgAFAAYQByAHQAeQAgAEEAZwByAGUAZQBtAGUAbgB0ACAA
# dwBoAGkAYwBoACAAbABpAG0AaQB0ACAAbABpAGEAYgBpAGwAaQB0AHkAIABhAG4A
# ZAAgAGEAcgBlACAAaQBuAGMAbwByAHAAbwByAGEAdABlAGQAIABoAGUAcgBlAGkA
# bgAgAGIAeQAgAHIAZQBmAGUAcgBlAG4AYwBlAC4wCwYJYIZIAYb9bAMVMB8GA1Ud
# IwQYMBaAFBUAEisTmLKZB+0e36K+Vw0rZwLNMB0GA1UdDgQWBBRhWk0ktkkynUoq
# eRqDS/QeicHKfTB9BgNVHR8EdjB0MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRBc3N1cmVkSURDQS0xLmNybDA4oDagNIYyaHR0cDovL2Ny
# bDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEQ0EtMS5jcmwwdwYIKwYB
# BQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20w
# QQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2Vy
# dEFzc3VyZWRJRENBLTEuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCdJX4bM02yJoFc
# m4bOIyAPgIfliP//sdRqLDHtOhcZcRfNqRu8WhY5AJ3jbITkWkD73gYBjDf6m7Gd
# JH7+IKRXrVu3mrBgJuppVyFdNC8fcbCDlBkFazWQEKB7l8f2P+fiEUGmvWLZ8Cc9
# OB0obzpSCfDscGLTYkuw4HOmksDTjjHYL+NtFxMG7uQDthSr849Dp3GdId0UyhVd
# kkHa+Q+B0Zl0DSbEDn8btfWg8cZ3BigV6diT5VUW8LsKqxzbXEgnZsijiwoc5ZXa
# rsQuWaBh3drzbaJh6YoLbewSGL33VVRAA5Ira8JRwgpIr7DUbuD0FAo6G+OPPcqv
# ao173NhEMIIGzTCCBbWgAwIBAgIQBv35A5YDreoACus/J7u6GzANBgkqhkiG9w0B
# AQUFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMDYxMTEwMDAwMDAwWhcNMjExMTEwMDAwMDAwWjBiMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMSEwHwYDVQQDExhEaWdpQ2VydCBBc3N1cmVkIElEIENBLTEw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDogi2Z+crCQpWlgHNAcNKe
# VlRcqcTSQQaPyTP8TUWRXIGf7Syc+BZZ3561JBXCmLm0d0ncicQK2q/LXmvtrbBx
# MevPOkAMRk2T7It6NggDqww0/hhJgv7HxzFIgHweog+SDlDJxofrNj/YMMP/pvf7
# os1vcyP+rFYFkPAyIRaJxnCI+QWXfaPHQ90C6Ds97bFBo+0/vtuVSMTuHrPyvAwr
# mdDGXRJCgeGDboJzPyZLFJCuWWYKxI2+0s4Grq2Eb0iEm09AufFM8q+Y+/bOQF1c
# 9qjxL6/siSLyaxhlscFzrdfx2M8eCnRcQrhofrfVdwonVnwPYqQ/MhRglf0HBKIJ
# AgMBAAGjggN6MIIDdjAOBgNVHQ8BAf8EBAMCAYYwOwYDVR0lBDQwMgYIKwYBBQUH
# AwEGCCsGAQUFBwMCBggrBgEFBQcDAwYIKwYBBQUHAwQGCCsGAQUFBwMIMIIB0gYD
# VR0gBIIByTCCAcUwggG0BgpghkgBhv1sAAEEMIIBpDA6BggrBgEFBQcCARYuaHR0
# cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1yZXBvc2l0b3J5Lmh0bTCCAWQG
# CCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMAZQAgAG8AZgAgAHQAaABpAHMA
# IABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8AbgBzAHQAaQB0AHUAdABlAHMA
# IABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAAdABoAGUAIABEAGkAZwBpAEMA
# ZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAAdABoAGUAIABSAGUAbAB5AGkA
# bgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0AZQBuAHQAIAB3AGgAaQBjAGgA
# IABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQAeQAgAGEAbgBkACAAYQByAGUA
# IABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgAZQByAGUAaQBuACAAYgB5ACAA
# cgBlAGYAZQByAGUAbgBjAGUALjALBglghkgBhv1sAxUwEgYDVR0TAQH/BAgwBgEB
# /wIBADB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRp
# Z2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHoweDA6oDig
# NoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9v
# dENBLmNybDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDAdBgNVHQ4EFgQUFQASKxOYspkH7R7for5XDStn
# As0wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQEF
# BQADggEBAEZQPsm3KCSnOB22WymvUs9S6TFHq1Zce9UNC0Gz7+x1H3Q48rJcYaKc
# lcNQ5IK5I9G6OoZyrTh4rHVdFxc0ckeFlFbR67s2hHfMJKXzBBlVqefj56tizfuL
# LZDCwNK1lL1eT7EF0g49GqkUW6aGMWKoqDPkmzmnxPXOHXh2lCVz5Cqrz5x2S+1f
# wksW5EtwTACJHvzFebxMElf+X+EevAJdqP77BzhPDcZdkbkPZ0XN1oPt55INjbFp
# jE/7WeAjD9KqrgB87pxCDs+R1ye3Fu4Pw718CqDuLAhVhSK46xgaTfwqIa1JMYNH
# lXdx3LEbS0scEJx3FMGdTy9alQgpECYwggfOMIIFtqADAgECAhNaAAAAHxMDUi/l
# /cB9AAIAAAAfMA0GCSqGSIb3DQEBBQUAMG8xEjAQBgoJkiaJk/IsZAEZFgJ1azET
# MBEGCgmSJomT8ixkARkWA25oczEaMBgGCgmSJomT8ixkARkWCm1vb3JmaWVsZHMx
# KDAmBgNVBAMTH01vb3JmaWVsZHMgRXllIEhvc3BpdGFsIFJvb3QgQ0EwHhcNMTMx
# MjAyMTMwODQ2WhcNMjExMjAyMTMxODQ2WjB0MRIwEAYKCZImiZPyLGQBGRYCdWsx
# EzARBgoJkiaJk/IsZAEZFgNuaHMxGjAYBgoJkiaJk/IsZAEZFgptb29yZmllbGRz
# MS0wKwYDVQQDEyRNb29yZmllbGRzIEV5ZSBIb3NwaXRhbCBJc3N1aW5nIENBIDEw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDBVev8uX2u0otMZSz3Cw0D
# YWosA2U8KWTnlFWO1u1Ro+JIha/CvwI2FhBinL4Elqf8cgSnw6PRbQN0s6L+OrsG
# OGMyf6SgIgj0YSFXi8bhivVB7mC5OuRoNJEYRVEmPoK/aJNTAqQKo4LBpso6rRc0
# gUI9sykKOqawFeRPvtKIvZFaEyZf6MqjKkb5t75hvNwoDt4BLNWBdnZdeWyly5w/
# ZZWdNtf24lE5/dM31k+6RMUxup9YTlE0JVcAhKZTzm+pIhogMFcEi+3/ws4f0IZg
# iyxKC57nG0cFJJrpK4uL3GxJU2AF7+j7YV0r00qNE1Z9Y0giqi5d3/MrzQdkVd7b
# AgMBAAGjggNcMIIDWDAQBgkrBgEEAYI3FQEEAwIBAjAjBgkrBgEEAYI3FQIEFgQU
# Bn8F1koYyygvzR8rBO+PK+nj+EswHQYDVR0OBBYEFEhLXjg47Bv4/Y3dPjV0XECB
# /iLmMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFBEgsbQZNLK+r6C+p4wdzwFxWR3XMIIB
# QwYDVR0fBIIBOjCCATYwggEyoIIBLqCCASqGgdlsZGFwOi8vL0NOPU1vb3JmaWVs
# ZHMlMjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBDQSxDTj1NRUhDQVJPT1QsQ049
# Q0RQLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNv
# bmZpZ3VyYXRpb24sREM9bW9vcmZpZWxkcyxEQz1uaHMsREM9dWs/Y2VydGlmaWNh
# dGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3RyaWJ1dGlv
# blBvaW50hkxodHRwOi8vY3JsLm1vb3JmaWVsZHMubmhzLnVrL3BraS9Nb29yZmll
# bGRzJTIwRXllJTIwSG9zcGl0YWwlMjBSb290JTIwQ0EuY3JsMIIBXQYIKwYBBQUH
# AQEEggFPMIIBSzCBzwYIKwYBBQUHMAKGgcJsZGFwOi8vL0NOPU1vb3JmaWVsZHMl
# MjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBDQSxDTj1BSUEsQ049UHVibGljJTIw
# S2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1t
# b29yZmllbGRzLERDPW5ocyxEQz11az9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0
# Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTB3BggrBgEFBQcwAoZraHR0cDov
# L2NybC5tb29yZmllbGRzLm5ocy51ay9wa2kvTUVIQ0FST09ULm1vb3JmaWVsZHMu
# bmhzLnVrX01vb3JmaWVsZHMlMjBFeWUlMjBIb3NwaXRhbCUyMFJvb3QlMjBDQSgy
# KS5jcnQwDQYJKoZIhvcNAQEFBQADggIBADojrDocfbx8QZRmsPTq2YMz8ctcRseM
# TRyriHltE1X97iF5xXBq80wcAOoY+3T0HiFVVstfPvFBPhyCuxFeHkogKQFlk9tC
# 7L/GU+Fy8iOjYnUVQvbzlN1NaZXo0Vu3lEeYomfVb9utNOk9Uv3V0eVMAUKrXeFY
# L1AykmRjQS6m2mIgOGkUx/S63AcalfoPyQ2YCgZL+/APqMb5YyJzXSZbxazrTNYK
# QmCgdmAPVQwWvF2iBW50Um+nxIHet3UIXpS4DaTmqwShRFh5BxGGjr7vXcam70be
# SiHZYC3QjLRcvPOcCkppilu/bvdq17ag6fDTv66zsvMQaS0o/Kaj4Uodg9ZKQhHo
# VLuBfPd2tT2bGMUZf7UfA3z+uKXWr8w5/0n8dl1Ygp/vF21qUSksFThT9nD58Tud
# DAQ/0CDQG/wSe2hpADS5cdqi0BgkA+rrehvLNK9ihMfkbnJhF4t094ixRxaUjnbE
# RcUaUEMzOxiEbHt0WiUculzBn2zSbcPVQp+B5UjtPcmO8pM6arKzCQMO8/lGzqfv
# a4+SDd0zP4ypBy9eh17DayYY/LRn79tCCNoV2/et3EeTCs4FLByJJM6+bn/t4RvR
# YQRUp4N+isZXQfO05TVmoq9+VrmNzivfLLIm0pvvscV4aLS8/EtVKeZJWO37IING
# AtrASMLApILHMYIDvzCCA7sCAQEwgYswdDESMBAGCgmSJomT8ixkARkWAnVrMRMw
# EQYKCZImiZPyLGQBGRYDbmhzMRowGAYKCZImiZPyLGQBGRYKbW9vcmZpZWxkczEt
# MCsGA1UEAxMkTW9vcmZpZWxkcyBFeWUgSG9zcGl0YWwgSXNzdWluZyBDQSAxAhMr
# AAh3rz6krheyLUQLAAIACHevMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTf7DYYxjPR+UwsUvUw
# 19GPzU2YIzANBgkqhkiG9w0BAQEFAASBgBIAkxSiEE1cVGvQTB/DAgNi4FfYrcGv
# qOZGe+/CSz/sUM4G+AzDRthpE8kjRuLEysXBF/E9baHUturSulOxldW6/5kuzsmv
# djF8o2Vp0oJX+pmjzvGD3HHjnRcfN8Jie54vEMl6SOvAOXM/7o641LSjNFBVORB/
# 9xGpz/2bgheroYICDzCCAgsGCSqGSIb3DQEJBjGCAfwwggH4AgEBMHYwYjELMAkG
# A1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRp
# Z2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgQXNzdXJlZCBJRCBDQS0xAhAD
# AZoCOv9YsWvW1ermF/BmMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZI
# hvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yMDA0MDkxODQ3MTZaMCMGCSqGSIb3DQEJ
# BDEWBBQjidS+VCoLk7H3BtNJijbwJnt2GjANBgkqhkiG9w0BAQEFAASCAQAuhq9i
# NiI7hW39xQOIKzPinRIgdYUUIDs57m+6/WCbCd8C8jsCp/SseVymXRrsPyONvN39
# 6fpbW2Jro4G9jaX478glCn7bgFXFl0twB4bY0QUvSTn9qR8iiRsCRTsOHvweEueZ
# S326LKC6P2I10Ho9kZBWEzmj8VGaO0K4dYHK4IvBf+gGXzQY94TJ8pGHfXQtyKUi
# Zy6XtOoWvm3ogXaeRwiHJHQLtAsri1TXJJenqcYegJyL0A9e2L4Tvihdyr8DKw+P
# 7oW5ciSMvZZvAA/qbAdjA5iL7ejdPJUZ2q+VkAJaNX+UjYslGvzilf0RRHC5yHtg
# rHnAKH6dMeMltYXo
# SIG # End signature block
