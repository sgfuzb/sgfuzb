<#
Three word password generator based on; https://xkpasswd.net/s/

{
 "num_words": 3,
 "word_length_min": 4,
 "word_length_max": 5,
 "case_transform": "RANDOM",
 "separator_character": "RANDOM",
 "separator_alphabet": [
  "-",
  "+",
  "=",
  ".",
  "*",
  "_",
  "|",
  "~",
  ","
 ],
 "padding_digits_before": 0,
 "padding_digits_after": 0,
 "padding_type": "NONE",
 "random_increment": "AUTO"
}

Dictionary from https://github.com/dwyl/english-words/

#>

$password = ""
$seps =   "-","+","=",".","*","_","|","~",","
$sep = get-random -inputobject $seps
$minword = 4
$maxword = 5
$numwords = 3

Write-host "Loading Dictionary..."
#$words = Get-Content "M:\Powershell\PasswordGen_words_alpha.txt" 
$words = Get-Content "M:\Powershell\PasswordGen_words_46.txt" 

Write-host "Selecting Words..."

# Generate dictionary of 4-8 letter words
<#
$words2 =@()
foreach ($word in $words) {
    if (($word.length -ge 4) -and ($word.length -le 6)){
        $words2 += ($word)
        #write-host -ForegroundColor Yellow $word   
    }
}
$words2 | out-file "M:\powershell\PasswordGen_words_46.txt"
#>

#<#
foreach ($i in 1..$numwords) {

    $word = ""
    while (($word.length -lt $minword) -or ($word.length -gt $maxword)){
        $word = $words | Get-Random
    }

    $password += $word
    if ($i -ne $numwords){ $password += $sep}
}

$password

#>