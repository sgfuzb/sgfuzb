$Servers = 
"MEHCITOTRN01",
"MEHDC4",
"MEHOETRANSLIVE",
"MEHSQL4",
"MEHSQLDEV4",
"MEHUAT-01",
"MEHUAT-02",
"MEHVECTRA",
"MEHVMC4",
"MEHVMC9"


ForEach ($server in $Servers) {

    $path = "\\" + $server + "\C$\Windows\Logs\CBS\CBS.log"

    $Contents = get-content -path $path 
    
    $InterestingLines = $Contents | Select-String -SimpleMatch '(ERROR_SXS_ASSEMBLY_MISSING)'

    if($InterestingLines) {
        #Retrieve unique Package names from error messages
        $Packages = @()
        foreach ($Line in $InterestingLines) {
            $Package  = $(($Line -split("'") )[1])
            $Package = $Package.Substring(0,$Package.Length - ($Package.split(".")[4]).Length - 1)
            if ($Packages -notcontains $Package) { $Packages += $Package }
        }
        Write-Host $server has $Packages
    } else {
        Write-Host $server has no missing SXS
    }
}
