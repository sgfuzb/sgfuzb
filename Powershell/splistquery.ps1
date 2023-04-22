# https://docs.microsoft.com/en-us/sharepoint/dev/sp-add-ins/complete-basic-operations-using-sharepoint-client-library-code
# https://www.sharepointdiary.com/2017/11/sharepoint-online-how-to-use-caml-query-in-powershell.html#ixzz6Mam2WX7F
# https://www.sharepointdiary.com/2017/11/sharepoint-online-how-to-use-caml-query-in-powershell.html#ixzz6MalKVFgm


# Add-PSSnapin -Name Microsoft.SharePoint.PowerShell 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Search") 
 
#$Cred= Get-Credential
#$siteUrl = "http://mehsp/it_servicedesk/Server_Inventory"
$siteUrl = "http://mehsp/it_servicedesk/database"

$Context = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL) 
#$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
#$Context.Credentials = $credentials 

#$List = $Context.Web.Lists.GetByTitle("Servers Inventory")
$List = $Context.Web.Lists.GetByTitle("Asset")

$ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery(10000)) 
$Context.Load($ListItems)
$Context.ExecuteQuery() 

Write-host "Total Number of Items:"$ListItems.count
 
#$ListItems.FieldValues | out-gridview

ForEach($Item in $ListItems)
{
    <#
    $Item.FieldValues.Item("Title") #assetno
    $Item.FieldValues.Item("SW_x0020_ID_x0020_Ref")
    $Item.FieldValues.Item("Department")
    $Item.FieldValues.Item("Floor")
    $Item.FieldValues.Item("Serial")
    $Item.FieldValues.Item("Manufacture")
    $Item.FieldValues.Item("Make")
    $Item.FieldValues.Item("Model")
    $Item.FieldValues.Item("ComputerNetworkName")
    $Item.FieldValues.Item("Comments") -replace '<[^>]+>','' -replace'&[^;]+;',' '
    #>

    if($Item.FieldValues.Item("Make") -eq "Computer"){

        $adname= $Item.FieldValues.Item("AD_x0020_NAME")
        if ($null -ne $adname){
            $authorUser = $context.Web.SiteUsers.GetById($adname.LookupId);
            $context.Load($authorUser);
            $context.ExecuteQuery();

            #$authorUser.Title
            #$authorUser.LoginName -replace "i:0#.w",""
            #$authorUser.Email
        }

        $Description = 
        $Item.FieldValues.Item("SW_x0020_ID_x0020_Ref") + " - "+
        $Item.FieldValues.Item("Department") + " - "+
        $authorUser.Title + " - "+
        $Item.FieldValues.Item("Comments") -replace '<[^>]+>','' -replace'&[^;]+;',' '

        Write-Host "==================================================="
        $Item.FieldValues.Item("ComputerNetworkName")
        $Description
    }
}



