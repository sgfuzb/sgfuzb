$ServerList = 'MEHDC1','MEHDC2','MEHDC3','MEHDC4'
$InterestingScopes = "192.168.15.0", "192.168.16.0", "192.168.17.0", "192.168.18.0", "192.168.19.0", "192.168.20.0","192.168.21.0","192.168.22.0"
$totalscopes = 0
$totalover80 = 0
$totalover90 = 0

Write-Host Listing scopes over 80% used;

$toplog = @()
$serscopelog = @()

Foreach($Server in $ServerList) 
{
    $ScopeList = Get-DhcpServerv4Scope -ComputerName $Server
    ForEach($Scope in $ScopeList.ScopeID) 
    {

        $ScopeInfo = Get-DhcpServerv4Scope -ComputerName $Server -ScopeId $Scope
        $ScopeStats = Get-DhcpServerv4ScopeStatistics -ComputerName $Server -ScopeId $Scope | Select-Object ScopeID,AddressesFree,AddressesInUse,PercentageInUse,ReservedAddress
        $ScopeReserved = (Get-DhcpServerv4Reservation -ComputerName $server -ScopeId $scope).count

        $totalscopes++

        if($ScopeStats.PercentageInUse -gt 80)
        {
            $totalover80++
            $toplog += [PSCustomObject]@{
               Server = $Server
               ScopeName = $ScopeInfo.Name
               PerInUse = $ScopeStats.PercentageInUse

            }
            
            if($ScopeStats.PercentageInUse -gt 90){ $totalover90++ }
            
        }

        foreach ($scope in $InterestingScopes){
            if($ScopeStats.ScopeID.IPAddressToString -eq $scope) { 
               $serscopelog += [PSCustomObject]@{
                  ScopeName = $ScopeInfo.Name
                  Scope = $ScopeStats.ScopeID.IPAddressToString
                  PerinUse = $ScopeStats.PercentageInUse}
            }
         }
      }
}

$toplog | Out-GridView
$serscopelog | Out-GridView

Write-Host "total scopes: " $totalscopes
Write-Host "total over 80%: " $totalover80
Write-Host "total over 90%: " $totalover90
Write-Host "See Gridviews!"

#END