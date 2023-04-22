# COR_ENABLE_Profiling diagnose

while ($true) {
    $Var = [Environment]::GetEnvironmentVariable("COR_ENABLE_PROFILING", "Machine")  

    
    If ($Var -eq 1) {
        
        Write-Host (Get-Date) : $Var -ForegroundColor Red
        #[console]::beep(500,300)
        [Environment]::SetEnvironmentVariable("COR_ENABLE_PROFILING", 0, "Machine")


    # Get tasklist check for new pids

    } else {
        #Write-Host (Get-Date) : $Var
    }

    Start-Sleep 1
}
