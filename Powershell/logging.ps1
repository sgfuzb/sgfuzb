function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
 
    [pscustomobject]@{
        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity
    } | write-host 
    #Export-Csv -Path "$env:Temp\LogFile.csv" -Append -NoTypeInformation
 }

 $foo = $false
if ($foo) {
    Write-Log -Message 'Foo was $true' -Severity Information
} else {
    Write-Log -Message 'Foo was $false' -Severity Error
}