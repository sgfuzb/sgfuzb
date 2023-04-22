
$pendingRebootTests = @(
    @{
        Name = 'RebootPending'
        Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction Ignore }
        TestType = 'ValueExists'
    }
    @{
        Name = 'RebootRequired'
        Test = { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction Ignore }
        TestType = 'ValueExists'
    }
    @{
        Name = 'PendingFileRenameOperations'
        Test = { Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction Ignore }
        TestType = 'NonNullValue'
    }
)


$computernames = "MEHVMC11","MEHVMC12","MEHVMC13","MEHVMC14","MEHVMC15","MEHVMC16","MEHVMC17","MEHVMC18"

$Results = @()

Foreach ($Computer in $computernames) {

    $session = New-PSSession -Computer $Computer
    foreach ($test in $pendingRebootTests) {
        $result = Invoke-Command -Session $session -ScriptBlock $test.Test
        if ($test.TestType -eq 'ValueExists' -and $result) {
            $bool = $true
        } elseif ($test.TestType -eq 'NonNullValue' -and $result -and $result.($test.Name)) {
            $bool = $true
        } else {
            $bool = $false
        }
        
        $Results += [PSCustomObject]@{
            ServerName = $Computer
            Test = $test.Name
            Result = $bool
        }

    }
    $session | Remove-PSSession
}

$Results