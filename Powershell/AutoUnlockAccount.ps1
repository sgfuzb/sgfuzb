
while ($true){
    $User = Get-ADuser -Identity MCVPUSER -Properties *

   	Write-Host "." -NoNewline

    if ($user.lockedout) {
        Write-Host (get-date).ToString($cultureENGB) -NoNewline
        Write-Host "Unlocking" -NoNewline
        $User | Unlock-ADAccount
    }
    Start-Sleep -Second 10
}
