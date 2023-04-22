Function Get-RandomPassword {
 <#
  .Synopsis
   This function creates a random password from a word list
  .Description
   This function creates a random password from a word list and adds a two digit number to the end.
   The word list should be in CSV format with two columns of words.
   The header on the first column should be "List1" and the header on the second "List2".
  .Example
   Get-RandomPassword -csv "C:\scripts\wordlist.csv"
   This will return a password that was randomly generated from the word list with a two digit number on the end.
   Example: SillySnake39
  #>
  Param(
   [Parameter(Mandatory=$false,Position=1)]
   [string]$csv
   ) #end param

    $csvExists = Test-Path "WordList.csv"
    if ($csvExists -eq $true) {
    $csv = "WordList.csv"
    } else {
    $csv = Read-Host -Prompt "Please enter location of CSV word list"
    }

    $WordList = Import-Csv $csv

    $list1 = $WordList.List1
    $list2 = $WordList.List2

    $word1 = Get-Random -InputObject $list1 -Count 1
    $word2 = Get-Random -InputObject $list2 -Count 1
    $num = Get-Random -Maximum 99 -Minimum 10

    Write-Host "Random Password: " $word1$word2$num
}
Function Set-RandomPassword {
 <#
  .Synopsis
   This function sets a random password for an Active Directory user based on a word list
  .Description
   This function sets a random password for an Active Directory user based on a word list
   Your word list should be in CSV format with two columns containing words you would like to use
   The header on the first column should be "List1" and the header on the second "List2"
  .Example
   Set-RandomPassword -csv "C:\scripts\wordlist.csv" -identity jsmith
   
   This will create a random password from the word list for user 'jsmith', such as "SillySnake32".
   By default, they will be required to change their password on the next login.
  .Example
   Set-RandomPassword -csv "C:\scripts\wordlist.csv" -identity jsmith -reset $false
   
   This will create a random password from the word list for user 'jsmith', such as "SillySnake32".
   By setting the -reset flag to $false, they will not be required to change their password on login.
  .PARAMETER identity
   This should be a single user account samAccountName that exists in Active Directory
 #>
 Param (
 [Parameter(Mandatory=$false)]
 [string]$csv,
 [Parameter(Mandatory=$true)]
 [string]$identity,
 [Parameter(Mandatory=$false)]
 [bool]$reset=$true
 ) #end param
 if ($reset -eq $true) {
    if (Get-MyModule -name "ActiveDirectory"){

	$csvExists = Test-Path "WordList.csv"
    if ($csvExists -eq $true) {
    $csv = "WordList.csv"
    } else {
    $csv = Read-Host -Prompt "Please enter location of CSV word list"
    }

    $WordList = Import-Csv $csv

    $list1 = $WordList.List1
    $list2 = $WordList.List2

    $word1 = Get-Random -InputObject $list1 -Count 1
    $word2 = Get-Random -InputObject $list2 -Count 1
    $num = Get-Random -Maximum 99 -Minimum 10
	
	$password = $word1 + $word2 + $num
	$securePassword = ConvertTo-SecureString -AsPlainText "$password" -Force
	
	Set-ADAccountPassword -Identity $identity -NewPassword $securePassword -Reset
	Set-ADUser -Identity $identity -ChangePasswordAtLogon $true
	
	Write-Host " The password for "$identity" has been set to: "$password
	Write-Host " They will be required to change their password upon login"
	} else {
	Write-Host "ActiveDirectory module is not on this system" -foregroundcolor red}
 } else {
    if (Get-MyModule -name "ActiveDirectory"){

    $csvExists = Test-Path "WordList.csv"
    if ($csvExists -eq $true) {
    $csv = "WordList.csv"
    } else {
    $csv = Read-Host -Prompt "Please enter location of CSV word list"
    }	

    $WordList = Import-Csv $csv

    $list1 = $WordList.List1
    $list2 = $WordList.List2g

    $word1 = Get-Random -InputObject $list1 -Count 1
    $word2 = Get-Random -InputObject $list2 -Count 1
    $num = Get-Random -Maximum 99 -Minimum 10
	
	$password = $word1 + $word2 + $num
	$securePassword = ConvertTo-SecureString -AsPlainText "$password" -Force
	
	Set-ADAccountPassword -Identity $identity -NewPassword $securePassword -Reset
	
	Write-Host " The password for "$identity" has been set to: "$password
	} else {
	Write-Host "ActiveDirectory module is not on this system" -foregroundcolor red}
   }
 }
 Function Get-MyModule 
{ 
 Param([string]$name) 
 if(-not(Get-Module -name $name)) 
{ 
 if(Get-Module -ListAvailable | 
 Where-Object { $_.name -eq $name }) 
{ 
 Import-Module -Name $name 
 $true 
} #end if module available then import 
 else { $false } #module not available 
} # end if not module 
 else { $true } #module already loaded 
} #end function get-MyModule
#Get-MyModule source: http://blogs.technet.com/b/heyscriptingguy/archive/2010/07/11/hey-scripting-guy-weekend-scripter-checking-for-module-dependencies-in-windows-powershell.aspx