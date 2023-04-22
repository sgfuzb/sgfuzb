$MaxRDSServer = 72
$Computernames = @()
$LogFilters = @()
$EventInfo = @()

For ($i = 1; $i -le $MaxRDSServer; $i++) {
    If ($i -lt 10) { $servername = "MEHRDS-0" + $i.ToString() } else { $servername = "MEHRDS-" + $i.ToString() }
    $ComputerNames += $servername
}

$Computernames = 
"MEHRDSTEST-01", "MEHRDSTEST-02", 
"MEHUAT-01", "MEHUAT-02"

$incorrect = 0

ForEach ($computer in $computernames){
    
    if(Test-Connection -ComputerName $computer -Count 1) {

        Write-Host "Checking $computer..."

        # RDS settings

        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $RegKey= $Reg.OpenSubKey("SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp")
        $RegKey.GetValue("SecurityLayer")

        # GPO settings

        $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
        $RegKey= $Reg.OpenSubKey("SOFTWARE\\Policies\\Microsoft\\Windows NT\\Terminal Services")
        $RegKey.GetValue("SecurityLayer")



        $RDPWMI = Get-WmiObject -ComputerName $computer  -class "Win32_TSGeneralSetting" -Namespace root\cimv2\terminalservices -Filter "TerminalName='RDP-tcp'"
        
        $RDPWMI
        #Set-WmiInstance -Path $RDPWMI.__path -arguments @{SSLCertificateSHA1Hash="06E754D90CFACDF72DFA2C84ABC5B6E4FBD21E41"}


        # Logs

        $MaxEvents = 2
        $StartTime = (Get-Date).AddHours(-8)
        $EndTime = (Get-Date)
        
        $LogFilters = 
        @{LogName="System";ID=36871}, # A fatal error occurred while creating a TLS client credential. The internal error state is 10013.
        @{LogName="System";ID=0} # Dummy no comma

        foreach ($LogFilter in $LogFilters) {

            $filter = @{LogName=$LogFilter.logname; ID=$logfilter.ID; StartTime=$StartTime; EndTime=$EndTime}
    
            $EventInfo += Get-WinEvent -ErrorAction SilentlyContinue -ComputerName $computer -FilterHashTable $Filter -MaxEvents $MaxEvents #| Where-Object {$_.Message -match $matchtext } 
        }

        $EventInfo
        
        # Permissions

        <#
        
        machinekeys = 
        administrators, full, folder only
        everyone, read
        
        
        NTFS permission problem
        C:\ProgramData\Microsoft\Crypto\RSA and
        grant "Network Services" Read permission to "MachineKeys"

        In the Certificates snap-in, in the console tree, expand Certificates (Local Computer), expand Personal, and navigate to the SSL certificate that you would like to use.
        Right-click the certificate, select All Tasks, and select Manage Private Keys.
        In the Permissions dialog box, click Add, type NETWORK SERVICE, click OK, select Read under the Allow checkbox, then click OK.

 # can get rid of SCHANNEL TLS 10013 errors

Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v2.0.50727]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319]
"SystemDefaultTlsVersions"=dword:00000001
"SchUseStrongCrypto"=dword:00000001

credits: https://blog.matrixpost.net/a-fatal-error-occurred-while-creating-a-tls-client-credential-the-internal-error-state-is-10013/


        #>

    }
}

#$output | Out-GridView


<#
https://techcommunity.microsoft.com/t5/microsoft-defender-for-endpoint/set-remote-desktop-security-level-to-tls-not-detecting-correctly/m-p/742930



# https://www.alitajran.com/a-fatal-error-occurred-while-creating-a-tls-client-credential/#:~:text=You%20learned%20why%20you%20get,36871%20errors%20in%20Event%20Viewer.

If (-Not (Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319')) {
    New-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319')) {
    New-Item 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SystemDefaultTlsVersions' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server')) {
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'Enabled' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server' -Name 'DisabledByDefault' -Value '0' -PropertyType 'DWord' -Force | Out-Null

If (-Not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client')) {
    New-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Force | Out-Null
}
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'Enabled' -Value '1' -PropertyType 'DWord' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'DisabledByDefault' -Value '0' -PropertyType 'DWord' -Force | Out-Null

Write-Host 'TLS 1.2 has been enabled. You must restart the Windows Server for the changes to take effect.' -ForegroundColor Cyan

http://h10032.www1.hp.com/ctg/Manual/c04517064.pdf


https://www.mvps.net/docs/how-to-secure-remote-desktop-rdp/

Enhance the encryption level with TLS

Another useful little trick is the RDP session encryption level and force TLS (Transport Layer Security) implementation.

TLS implementation:

Click on Start > Run > regedit
Go to HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\SecurityLayer
Set the value to 2
Security levels description:

Security Layer 0 – With a low security level, the remote desktop protocol is used by the client for authentication prior to a remote desktop connection being established. Use this setting if you are working in an isolated environment.
Security Layer 1 – With a medium security level, the server and client negotiate the method for authentication prior to a Remote Desktop connection being established. As this is the default value, use this setting only if all your machines are running Windows.
Security Layer 2- With a high security level, Transport Layer Security, better knows as TLS is used by the server and client for authentication prior to a remote desktop connection being established. 

Encryption level:

Go to HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\MinEncryptionLevel
Set the value to 3. You can set value to 4 but only if both machines support this type of encryption.
Security levels description:

Security Layer 1 – With a low security level, communications sent from the client to the server are encrypted using 56-bit encryption. Data sent from the server to the client is not encrypted. This setting is not recommended as you can be exposed to various attacks.
Security Layer 2 – Having a client compatible security level, communications between the server and the client are encrypted at the maximum key strength supported by the client. Use this level when the Terminal Server is running in an environment containing mixed or legacy clients as this is the default setting on your OS.
Security Layer 3 – With a high security level, communications between server and client are encrypted using 128-bit encryption. Use this level when the clients that access the Terminal Server also support 128-bit encryption. If this option is set, clients that do not support 128-bit encryption will not be able to connect.
Security Layer 4 – This security level is FIPS-Compliant, meaning that all communication between the server and client are encrypted and decrypted with the Federal Information Processing Standard (FIPS) encryption algorithms. Use this setting for maximum security but only if both machines support this type of encryption.

#>