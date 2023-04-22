<#/**************************************************************************
*                                                                           *
*                                  NOTICE                                   *
*                                                                           *
*           COPYRIGHT (c) 1998-2019 DATACORE SOFTWARE CORPORATION           *
*                                                                           *
*                            ALL RIGHTS RESERVED                            *
*                                                                           *
*                                                                           *
*    This Computer Program is CONFIDENTIAL and a TRADE SECRET of            *
*    DATACORE SOFTWARE CORPORATION. Any reproduction of this program        *
*    without the express written consent of DATACORE SOFTWARE CORPORATION   *
*    is a violation of the copyright laws and may subject you to criminal   *
*    prosecution.                                                           *
*                                                                           *
*****************************************************************************#>





###################################################################################################################################
# iSCSI_Best_Practices.ps1
#
### THIS INFORMATION IS GATHERED BY A FUNCTION. ONLY MODIFY VALUE BEHIND ":" !!!
# Script-Version:     3.9
# Script-Date:        2019-11-25
###################################################################################################################################





#region DOCUMENTATION
###################################################################################################################################
<#
    .SYNOPSIS
        This script performs a series of iSCSI settings changes according to the DataCore Software iSCSI Best Practices or (if needed
        the restoration of known default settings).
       
    .DESCRIPTION
        IMPORTANT WARNING: Executing this script while the server is processing I/O will cause a temporary interruption of iSCSI I/O 
                           on the selected ports that are being configured.
        
        The script can be used in three different ways.
        1. Interactive mode - requires a interactive PowerShell session (e.g. when executed by a user manually)
        2. Batch mode using 'Netadapters' parameter - this is a legacy / backward compatibility mode. It is deprecated.
        3. Batch mode using 'adapterIdentifier' parameter - this should be used as a replacement of the 'NetAdapters' parameter for future use.
           The string / parameter can be used for exact matching of port names (always tried first). If no exact adapter name is found it
           falls back to a simple matching string. E.g. if all ports used for iSCSI in the system have the string "iscsi" in their name, 
           then this can be used for NIC detection.

        The script provides the following modes of operations:
        1. Setting the required settings for iSCSI traffic on selected / specified Ethernet ports.
        NOTE: The following modes are not applicable to the deprecated parameter 'NetAdapters'. Use 'adapterIdentifiert' instead.
        2. Restore default settings on selected / specified Ethernet ports.
        3. Same as 2., but also include restoration of all other OS default settings, for instance the powerplan. 
           This can be used in test environments to reset the system to a known state.

	    This script will set/unset the following parameters to the system (depending on the mode of operation):
	    - Global settings
	        - POWER PLAN TO HIGH PERFORMANCE
	        - CONGESTION PROVIDER FOR iSCSI set to DataCenter
            - Configure Net-TCPSettings for "DatacenterCustom" in order to specify the optimal TCP settings to apply to all iSCSI TCP connections,
            - LMHOSTS configuration (disable lookup)
	    - Per NIC settings
    	    - DNS registration
	        - WINS
	        - net adapter bindings
	        - nagle and delayed ack
	        - adapter power saving
	        - SRIOV
	        - RSC
	        - RSS

        - DataCore recommends using this script on new and existing installations to configure iSCSI settings for dedicated frontend, backend and mirrored ports that handle iSCSI traffic.
        - It is important that all NICs in the iSCSI-path are configured through this script. This includes vEthernet devices as well as physical NICs.
        - Refer to http://datacore.custhelp.com/app/answers/detail/a_id/1626/~/sansymphony---iscsi-best-practices#Other_Settings for detailed iSCSI information.
        - For existing installations, it should be run immediately following the installation of this update on existing installations while in maintenance mode
          (before restarting the server) to avoid unnecessary disruption.
        - This script needs only to be run once on each DataCore Server and it is expected that new port settings will survive future upgrades. 
        - For new installations, it should be run after the DataCore Servers have been configured and port roles have been defined. 
        - However, the script must be rerun anytime new Ethernet ports are added to the DataCore Server and configured for iSCSI traffic.
        - This script can only be used on DataCore Servers running Microsoft Windows 2012 or later. 

        IMPORTANT WARNING: Executing this script while the server is processing I/O will cause a temporary interruption of iSCSI I/O 
                           on the selected ports that are being configured.
            
    .LINK
        http://datacore.custhelp.com/app/answers/detail/a_id/1626/~/sansymphony---iscsi-best-practices#Other_Settings

    .PARAMETER NetAdapters [String]
   	    The name of the network adapter you wish to configure. Does an exact match of the name (e.g. works on one interface).
        If the network adapter has a white space in its name this needs quoting. Example: "Ethernet 1" or 'Ethernet 1'
        IMPORTANT: This parameter is available to provide backwards-compatibility with older versions of this script. 
                   It does NOT allow the usage of the '-RestoreDefaults' and '-IncludeGlobalSettings' switch.
   
    .PARAMETER adapterIdentifier [String]
   	    The name of the network adapter or a matching string. 
        Using this parameter causes the script to first try to detect an exact match (case-insensitive equals) of the string (e.g. one NIC). 
        If none is found then the provided string is used as the base of a substring-search. Please refer to the examples below.
        If the network adapter has a white space in its name this needs quoting. Example: "Ethernet 1" or 'Ethernet 1'

    .PARAMETER restoreDefaults [Switch]
        Indicates that the Port-based settings should be restored to the default. The configuraiton of Net-Transportfilters (even if depending on NIC/Ports)
        is considered to be a global setting.
    
    .PARAMETER includeGlobalSettings [Switch]    
        Indicates in combination with the restoreDefaults parameter that also the global settings like Powerplan, Net-Transportfilter, LMHOSTS lookup should
        be set to the default values.

    .PARAMETER Force [Switch]
	    When specified, the operation will not request for user confirmation.
        This is not used / taken into consideration when the script is run in non-userinteractive mode.

    .EXAMPLE
	    .\iSCSI_Best_Practices.ps1 
            -> This will run the script in user interactive mode and set iSCSI port settings

        .\iSCSI_Best_Practices.ps1  -Force 
            -> This will run the script in user interactive mode and set iSCSI port settings, but wont ask for user confirmation after selection of ports

        .\iSCSI_Best_Practices.ps1  -RestoreDefaults 
            -> This will run the script in user interactive mode and remove iSCSI port settings from selected ports.
               Important: This wont remove "Global System Settings"

        .\iSCSI_Best_Practices.ps1  -RestoreDefaults -includeGlobalSettings
            -> This will run the script in user interactive mode and remove iSCSI port settings from selected ports. It also removes any known global settings

        .\iSCSI_Best_Practices.ps1  -Netadapters "<adaptername>"
            -> This will run the script in batch mode, but will request user confirmation if a user interactive session is detected.
               It provides backward compatibility to earlier versions of the script.

        .\iSCSI_Best_Practices.ps1  -Netadapters "<adaptername>" -Force
            -> This will run the script in batch mode, skipping user confirmation generally.
               It provides backward compatibility to earlier versions of the script.

        .\iSCSI_Best_Practices.ps1  -adapterIdentifier "<adapterIdentifier>"
            -> This will run the script in batch mode and tries to match an exact adaptername.
               If no adapter with the exact (case insensitive) is found then the adapterIdentifier acts as a matching string.
               As an example when adapterIdentifier is "iSCSI" and no adapter with name iSCSI is found, then it would match ethernet port names like
               iSCSI-FE-01, iSCSI1, iSCSI-BE, etc.

        .\iSCSI_Best_Practices.ps1  -adapterIdentifier "<adapterIdentifier>" -RestoreDefaults
            -> Same as above, but would restore default settings to detected adapters

        .\iSCSI_Best_Practices.ps1  -adapterIdentifier "<adapterIdentifier>" -RestoreDefaults -includeGlobalSettings
            -> Same as above, but would restore the global settings alongside with default settings of detected adapters.

    .NOTES
        .
#>
###################################################################################################################################
# CHANGELOG
#
# Version 3.9  - Added support for Windows 2019 (testing only).
#
# Version 3.8  - Correcting an character and encoding error for some Asian locales in the Net-TCP-Settings section (Line 1904).
#
# Version 3.7  - Correcting log messages (spelling mistakes).
#
# Version 3.6  - Catching an unhandled error when the MS-iSCSI Initator / Service is not installed.
#
# Version 3.5  - If Hyper-V vSwitch is "IOV-Enabled" don´t disable SRIOV on physical NIC attached to the switch
#              - Display a warning if IOV-enabled vSwitch physical NIC does not has SRIOV enabled.
#              - On restart of the adapter wait until it is back online (has link) before proceeding with the next adapter
#              - Correcting overview of adapters
#                - which did not display lines with ID´s than one digit correctly. Now up to 99 Adapter IDs are correctly displayed.
#                - to display as an increasing ID. This was achieved by changing / forcing the hashtable to an [ordered] type.
#
# Version 3.4  - Modifying Get-DcsPort (line 580 & 1172) calls to use a Server-Object instead of the hostname to prevent erratic 
#                behavior of the Cmdlet.
#
# Version 3.3  - Adding validation for 'NetAdapters' and 'adapterIdentifier' parameters. The parameters must
#                   - not be empty / null.
#                   - be at least 3 characters long.
#              - Modified code so the 'NetAdapters' parameter mode would not fail when multiple adapters are returned by the command
#                'get-netadapter'.
#              - Introduced a 'configure-NICs' function which is used by the 'NetAdapters' and 'adapterIdentifier' parameters
#                   - The detected NetAdapters will be logged and displayed to the user in an interactive session prior to asking 
#                     the confirmation question. 
#                   - A check has been implemented to prevent that all Network adapters are configured. At least one needs to remain
#                     in normal operation.
#              - Introducing more regions to better separate code in the 'functions' region.
#
# Version 3.2  - Added check if the script runs under an administrative user.
#              - Adjusting several log messages.
#
# Version 3.1  - Added a changelog area in the 'documentation' section.
#              - Missing variable initialization in area for handling the 'adapterIdentifier' parameter lead to a false postive
#                error message.
#              - Modified documentation section to
#                   - explain the usage of 'NetAdapters' and 'adapterIdentifier' better. Used explanation was misleading.
#                   - outline that on blanks in 'NetAdapters' and 'adapterIdentifier' parameter the value would need to be quoted.
#
# Version 3.0  - Initial version & rewrite of the set-iSCSIPortSettings.ps1 script.
###################################################################################################################################
#endregion





#region PARAMETERS
###################################################################################################################################
###### PARAMETERS
[CmdletBinding(DefaultParameterSetName="Default")]
Param(
        ### THIS PARAMETER IS KEPT AS A LEGACY AND TO PROVIDE BACKWARDS COMPATIBILITY WHEN THE PREVIOUS VERSION OF THE SCRIPT IS USED IN OTHER SCRIPTS
        #The name of the network adapter you wish to configure. For a complete list, use Get-NetAdapter.
        [Parameter(ParameterSetName="adapterName", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Mandatory=$false, HelpMessage="The name of the network adapter you wish to configure. For a complete list, use Get-NetAdapter.")]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3,100)]
        [string]
        $NetAdapters,
    
        # Please provide the name of the adapter that should be configured or a substring of the name to match adapters.
        [Parameter(ParameterSetName="adapterIdentifier", Mandatory=$false, HelpMessage="Please provide the name of the adapter that should be configured or a substring of the name to match adapters.")]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3,100)]
	    [string]
	    $adapterIdentifier,

        # Please indicate if the defaults of an adapter should be restored.
        [Parameter(ParameterSetName="Default", Mandatory=$false, HelpMessage="Please indicate if the defaults of an adapter should be restored.")]
        [Parameter(ParameterSetName="adapterIdentifier", Mandatory=$false, HelpMessage="Please indicate if the defaults of an adapter should be restored.")]
	    [switch]
	    $restoreDefaults,

        # Please indicate if also the global settings (like PowerPlan, Nettransportfilter, etc.) should be restored to defaults.
        [Parameter(ParameterSetName="Default", Mandatory=$false, HelpMessage="Please indicate if also the global settings (like PowerPlan, Nettransportfilter, etc.) should be restored to defaults.")]
	    [Parameter(ParameterSetName="adapterIdentifier", Mandatory=$false, HelpMessage="Please indicate if also the global settings (like PowerPlan, Nettransportfilter, etc.) should be restored to defaults.")]
        [switch]
	    $includeGlobalSettings,

        # When specified, the operation will not request for user confirmation.
        [Parameter(ParameterSetName="Default", Mandatory=$false, HelpMessage="When specified, the operation will not request for user confirmation.")]
        [Parameter(ParameterSetName="adapterIdentifier", Mandatory=$false, HelpMessage="When specified, the operation will not request for user confirmation.")]
        [Parameter(ParameterSetName="adapterName", Mandatory=$false, HelpMessage="When specified, the operation will not request for user confirmation.")]
        [Switch]
        $Force
    )
#endregion





#region FUNCTIONS
#region OTHER NEEDED FUNCTIONS
##### OTHER NEEDED FUNCTIONS
#----------------------------------------------------------------------------------------------------------------------------------



function analyze-AdapterDependency
{
    param (
            # Please provide the adapter object which one we will do the analysis on.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which one we will do the analysis on.")]
		    $chosenAdapter
          )

    try
    {
        $myChosenAdapter = $null
        $myChosenAdapter = $chosenAdapter
        
        $adaptersToConfigure = @()
        $adaptersToConfigure += $myChosenAdapter
                    
        ### Check if it is a virtual NIC (vEthernet)
        try
        {
            $vEthernetAdapter = $null
            $vEthernetAdapter = get-vmnetworkadapter -managementos -Erroraction Stop | where { "$( $_.deviceid )" -ieq "$( $myChosenAdapter.InstanceID )" }
        }
        catch
        {
            # do nothing
        }
                            
        if ( -not ( $vEthernetAdapter -eq $null ) )
        {
            try
            {
                $vmSwitch = $null
                $vmSwitch = get-vmswitch -erroraction Stop | where { $_.id -ieq $vEthernetAdapter.SwitchId }
                # We override the chosen adapter variable here, because it does not make sense to use the old object.
                $myChosenAdapter = $null
                $myChosenAdapter = get-netAdapter -erroraction stop | where { $_.interfacedescription -ieq "$($vmSwitch.netadapterinterfacedescription)" }
                if ( $myChosenAdapter -eq $null )
                {
                    throw("analyze-AdapterDependency: error switch")
                }
                else
                {
                    $adaptersToConfigure += $myChosenAdapter
                }
            }
            catch
            {
                # do nothing
            }
        }
                            
        # Check if the chosen adapter is a netlbfoteam
        try
        {
            $netTeam = $null
            $netTeam = Get-NetLbfoTeam -Name "$($myChosenAdapter.Name)" -ErrorAction Stop
        }
        catch
        {
            # do nothing
        }
        # check if the adapter is an SET (switch enabled team)
        if ( $netTeam -eq $null )
        {
            try
            {
                $netTeam = $null
                $netTeam = Get-NetSwitchTeam -Name "$($myChosenAdapter.Name)" -ErrorAction Stop
            }
            catch
            {
                # do nothing
            }
        }

        if ( -not ( $netTeam -eq $null ) )
        {
            # try to get netlbfoteam member
            try
            {
                $teamMembers = $null
                $teamMembers = $netTeam | Get-NetLbfoTeamMember -ErrorAction Stop
                                    
            }
            catch
            {
                # do nothing
            }

            # try to get netswitchteam member
            if ( $teamMembers -eq $null )
            {
                try
                {
                    $teamMembers = $null
                    $teamMembers = $netTeam | Get-NetSwitchTeamMember -ErrorAction Stop
                }
                catch
                {
                    # do nothing
                }
            }

            # Adding members to the adapters list.
            foreach ( $member in $teamMembers )
            {
                $teamMemberAdapter = $null
                $teamMemberAdapter = $member | get-netadapter -ErrorAction Stop
                $adaptersToConfigure += $teamMemberAdapter
            }
        }

        # Return the array of adapters that need configuration
        return $adaptersToConfigure
    }
    catch
    {
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function create-AdapterHashtable
{
    # Version 1.1

    param (
            # Should all adapters be displayed? Default only prints with active IP-addresses.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Should all adapters be displayed? Default only prints with active IP-addresses.")]
		    [switch]$all
          )

    try
    {
        ### Getting adapters and find out if they need to be considered for listing
        $netadapters = $null
        $netadapters = Get-NetAdapter -ErrorAction Stop | Sort-Object name

        $netadapterHashtable = [ordered]@{}
        $counter = 1
        foreach ( $netadapter in $NetAdapters )
        {
            if ( $all -eq $true )
            {
                $netadapterHashtable.add([int32]$counter,"$($netadapter.name)")
                $counter++
            }
            else
            {
                # we exclude all ports which do not have an active ipv4 and ipv6 address. These are pnics bound to netlbfo-teams or vswitches for instance
                try
                {
                    $adapterIPs = $null
                    $adapterIPs = $( $netadapter | Get-NetIPAddress -ErrorAction Stop | Sort-Object AddressFamily ).IPAddress
                }
                catch
                {
                    # do nothing
                }

                if ( -not ( $adapterIPs -eq $null ) )
                {
                    $netadapterHashtable.add("$counter","$($netadapter.name)")
                    $counter++
                }
                else
                {
                    # skipping due to missing ipv4 / ipv6 binding
                }
            }
        }

        return $netadapterHashtable
    }
    catch
    {
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function dcsx-connection
{
    param (
            # Provide the hostname (or IP) or a list of hostnames (or IPs) separated by comma to which connect. If it is empty the system will use localhost / the local server.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Provide the hostname (or IP) or a list of hostnames (or IPs) separated by comma to which connect. If it is empty the system will use localhost / the local server.")]
		    [string]$server = "localhost",

            # Provide the action that is to be executed. Valid values are 'connect', 'disconnect', 'cleanup'. Default is 'connect'.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Provide the action that is to be executed. Valid values are 'connect', 'disconnect', 'cleanup'. Default is 'connect'.")]
	        [ValidateSet('connect','disconnect','cleanup')]
            [string]$action = "connect",

            # On 'connect' action: How many retries are allowed? Allows a range from '1' to '15'. Defaults to '5'.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "On 'connect' action: How many retries are allowed? Allows a range from '1' to '15'. Defaults to '5'.")]
            [ValidateRange(1,15)]
		    [int32]$retryCount = 5,

            # On 'connect' action: What is the retry timout interval in seconds? Allows a range from '5' to '60'. Default to '25'.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "On 'connect' action: What is the retry timout interval in seconds? Allows a range from '5' to '60'. Default to '25'.")]
		    [ValidateRange(5,60)]
            [int32]$retryTimeOut = 25
    )

    # Error Variable
    $ErrorOccured = $false

    # Get the servers information and prepare for the main loop
    $servers = @()
    if ( $server -imatch "," )
    {
        $servers = $server -split ","
    }
    else
    {
        $servers = $server
    }

    # Main loop / Doing the work
    foreach ( $item in $servers )
    {
        $result = $null
        $retryCounter = 1
        if ( $action -ieq "connect" )
        {
            while ( $retryCounter -le $retryCount )
            {
                $connected = $false
                try
                {
                    $result = Connect-DcsServer -Server $item -ErrorAction Stop
                    $connected = $true
                    break
                }
                catch
                {
                    if ( $( $_.exception.message ) -imatch "The caller was not authenticated by the service." )
                    {
                        # Non recoverable error. If the password is wrong, then it is wrong on the other servers as well
                        throw("Wrong user or password for DCSX connection.")
                    }
                    elseif ( $( $_.exception.message ) -imatch "The term 'Connect-DcsServer' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.")
                    {
                        # Non recoverable error. Without cmdlets we can not do anything.
                        throw("DataCore Cmdlets not loaded. Can not continue.")
                    }
                    else
                    {
                        if ( $( $_.exception.message ) -imatch "Not connected successfully." )
                        {
                            # Break inner loop on "not connected successfully", but try other servers if provided.
                            break
                        }
                        elseif ( $( $_.exception.message ) -imatch "Could not connect to net.tcp://" -or $( $_.exception.message ) -imatch "No DNS entries exist for host" )
                        {
                            # Break inner loop if the server is not reachable or no DNS entry was found.
                            break
                        }
                        else 
                        {
                            sleep $retryTimeOut
                            $retryCounter++
                            if ( $retryCounter -gt $retryCount )
                            {
                                break
                            }
                        }
                    }
                }

                # Break outer loop
                if ( $conenct -eq $true )
                {
                    break
                }
            }
        }
        elseif ( $action -ieq "disconnect" )
        {
            $connections = $null
            $connections = Get-DcsConnection
            foreach ( $connection in $connections )
            {
                if ( $connection -ieq "$item" )
                {
                    try
                    {
                        $result = $connection | Disconnect-DcsServer -ErrorAction Stop
                    }
                    catch
                    {
                        $ErrorOccured = $true
                    }
                }
            }
        }
        elseif ( $action -ieq "cleanup" )
        {
            try
            {
                $result = Get-DcsConnection | Disconnect-DcsServer -ErrorAction Stop
                break
            }
            catch
            {
                $ErrorOccured = $true
            }
        }
    }

    # If we want to connect, but are not connected after the loop -> error
    if ( $action -ieq "connect" -and $connected -eq $false)
    {
        $ErrorOccured = $true        
    }

    # Return the value of the function
    if ( $ErrorOccured -eq $true )
    {
        return $false
    }
    else
    {
        return $true
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function display-Adapters
{
    # Version 1.2

    param (
            # Hashtable of the adapters.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Hashtable of the adapters.")]
		    $netadapterHashtable
          )

    ### Create an array with all potential netadapters we have in the system.
    $adapterObjects = @()
    foreach ( $element in ( $netadapterHashtable.GetEnumerator() | Sort-Object name ) )
    {
        $adapterObjects += Get-NetAdapter -Name "$($element.Value)"
    }

    ### Get list of dcs ports (iSCSI Targets)
    if ( $dcsInstalled -eq $true )
    {
        $dcsPorts = $null
        $dcsPorts = Get-Dcsport -Type iSCSI -MachineType Servers -Machine $( Get-DcsServer -Server $(hostname) -ErrorAction Stop ) -ErrorAction Stop
    }

    $idLengthMaximum = $null
    $idLengthMaximum = $( $( $netadapterHashtable.Keys ) | Measure-Object -Maximum -Property Length ).Maximum
    $nameLengthMaximum = $null
    $nameLengthMaximum = $( $( $netadapterHashtable.Values ) | Measure-Object -Maximum -Property Length ).Maximum
    $myNameString = $null
    $myNameString = unify-StringLength -originalString "NAME" -expectedLength $nameLengthMaximum

    $myStateLengthMaximum = $null
    $myStateLengthMaximum = $( @( $adapterObjects.status ) | Measure-Object -Maximum -Property Length ).Maximum
    if ( $myStateLengthMaximum -lt 6 )
    {
        $myStateLengthMaximum = 6
    }
    $myStateString = $null
    $myStateString = unify-StringLength -originalString "STATUS" -expectedLength $myStateLengthMaximum
        
    $messageString = $null
    $messageString =  "    ID    $myNameString    LINKSPEED   MAC-ADDRESS          $myStateString    INTERFACEDESCRIPTION"

    write-host " "
    write-host "$messageString"

    ### Analyze the elements
    foreach ( $element in ( $netadapterHashtable.GetEnumerator() ) )
    {
        $adapterObject = $null
        $adapterObject = Get-NetAdapter -Name "$($element.Value)" -ErrorAction Stop
        $dcsPortObject = $null
        $dcsPortObject = $dcsPorts | where { $_.idinfo.connectionname -ieq "$($element.value)" -and ( $_.ServerPortProperties.Role -ieq "FrontEnd" -or $_.ServerPortProperties.Role -ieq "Mirror" ) }
        try
        {
            $adapterIPs = $null
            $adapterIPs = $( $adapterObject | Get-NetIPAddress -ErrorAction Stop | Sort-Object AddressFamily ).IPAddress
        }
        catch
        {
            # do nothing
        }

        try
        {
            $iSCSISessions = $null
            $iSCSISessions = get-IscsiTargetPortal -ErrorAction Stop
            $iSCSIBE = $false
            foreach ( $adapterIP in $adapterIPs )
            {
                if ( $iSCSISessions.InitiatorPortalAddress -icontains $adapterIP )
                {
                    $iSCSIBE = $true
                }
            }
        }
        catch
        {
            # do nothing
        }

        ### Creating the string
        $adapterName = $null
        $adapterName = unify-StringLength -originalString "$($element.Value)" -expectedLength $nameLengthMaximum
        
        $linkSpeed = $null
        $linkSpeed = unify-StringLength -originalString "$( $adapterObject.LinkSpeed )" -expectedLength 8

        $status = $null
        $status = unify-StringLength -originalString "$( $adapterObject.Status )" -expectedLength $myStateLengthMaximum

        if ( $($element.Name).length -eq 1 )
        {
            $spacer = "     "
        }
        elseif ( $($element.Name).length -eq 2 )
        {
            $spacer = "    "
        }
        $messageString = $null

        $messageString =  "--> $($element.Name)" + "$spacer" + "$adapterName" + "    " + "$linkSpeed" + "    " + "$( $adapterObject.MacAddress )" + "    " + "$status" + "    " + "$( $adapterObject.InterfaceDescription )"

        # When we have a port object
        if ( -not ( $dcsPortObject -eq $null ) )
        {
            write-host $messageString -ForegroundColor $dcsColor
            if ( -not ( "$adapterIPs" -eq "" ) )
            {
                write-host "          \ IPs: $adapterIPs" -ForegroundColor $dcsColor
            }
        }
        # When we detected iSCSI sessions as source
        elseif ( $iSCSIBE -eq $true )
        {
            write-host $messageString -ForegroundColor $msiscsiColor
            if ( -not ( "$adapterIPs" -eq "" ) )
            {
                write-host "          \ IPs: $adapterIPs" -ForegroundColor $msiscsiColor
            }
        }
        # all other ports
        else
        {
            write-host $messageString
            if ( -not ( "$adapterIPs" -eq "" ) )
            {
                write-host "          \ IPs: $adapterIPs"
            }
        }
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function load-DcsCmdlets
{
    # Local error variable
    $errorOccured = $false
    
    ### Loading the DataCore PowerShell extension
    try
    {
        # Get the installation path of SANsymphony
        $bpKey = 'BaseProductKey'
        $regKey = Get-Item "HKLM:\Software\DataCore\Executive" -ErrorAction Stop -WarningAction SilentlyContinue
        $strProductKey = $regKey.getValue($bpKey)
        $regKey = Get-Item "HKLM:\$strProductKey" -ErrorAction Stop -WarningAction SilentlyContinue
        $installPath = $regKey.getValue('InstallPath')

        # Finally import the module if not already loaded
        if ( -not ( get-module -Name DataCore.Executive.Cmdlets -ErrorAction SilentlyContinue ) )
        {
            $result = $null
            $result = Import-Module "$installPath\DataCore.Executive.Cmdlets.dll" -DisableNameChecking -ErrorAction Stop `
	         -WarningAction SilentlyContinue
        }
    }
    catch
    {
        $errorOccured = $true
    }

    if ( $errorOccured -eq $false )
    {
        return $true
    }
    else
    {
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function LOG-Writer
{
    param (
		[parameter(Mandatory = $true)]
		[string]$Message,
        [parameter(Mandatory = $false)]
        [ValidateSet('SUCCE','ERROR','WARNI','INFOR','VERBO','DEBUG')]
		[string]$Level = "INFOR",
        [parameter(Mandatory = $false)]
		[switch]$LogOnly,
        [parameter(Mandatory = $false)]
		[switch]$CliOnly,
        [parameter(Mandatory = $false)]
		[switch]$CliUsesMessageOnly
	)

    #region ### Private Helper Functions ###
    # This function provides the scriptname
    function Get-ScriptBaseName
    {
        [OutputType([string])]
	    param ()
        try
        {
	        if ( -not ( $hostinvocation -eq $null ) ) 
	        {
		        $scriptFullPath = $hostinvocation.MyCommand.path
	        }
	        else
	        {
		        $scriptFullPath = $script:MyInvocation.MyCommand.Path
	        }
            $scriptBaseName = $( get-item -Path $scriptFullPath -Force -ErrorAction stop ).BaseName
            return $scriptBaseName
        }
        catch
        {
            return $false
        }
    }
    # This function provides the working directory.
    function Get-WorkingDirectory
    {
	    [OutputType([string])]
	    param ()
        try
        {
	        if ( -not ( $hostinvocation -eq $null ) ) 
	        {
		        Split-Path $hostinvocation.MyCommand.path
	        }
	        else
	        {
		        Split-Path $script:MyInvocation.MyCommand.Path
	        }
        }
        catch
        {
            return $false
        }
    }
    # This function writes to the CLI
    function CLI-Writer
    {
	    param (
		    [parameter(Mandatory = $true)]
		    [string]$Message,
            [parameter(Mandatory = $false)]
            [ValidateSet('SUCCE','ERROR','WARNI','INFOR','VERBO','DEBUG')]
		    [string]$Level = "INFOR"
	    )
	
	    if ( [Environment]::UserInteractive -eq $true -and -not ( $( get-process -Id $PID ).MainWindowHandle -eq 0 ) )
	    {
            if ( $Level -ieq "INFOR" ) { $color = "White" }
            elseif ( $Level -ieq "SUCCE" ) { $color = "Green" }
            elseif ( $Level -ieq "ERROR" ) { $color = "Red" }
            elseif ( $Level -ieq "WARNI" ) { $color = "Yellow" }
            elseif ( $Level -ieq "VERBO" ) { $color = "DarkGray" }
            elseif ( $Level -ieq "DEBUG" ) { $color = "Gray" }
            
		    try
		    {
			    Write-Host $Message -ForegroundColor $color
		    }
		    catch
		    { 
                # Suppress exceptions 
            }
	    }
    }
    # This function writes to the LOG file. Tries to determine the current script path. If not possible it logs to users desktop.
    function FILE-Writer
    {
	    param (
		    [parameter(Mandatory = $true)]
		    [string]$Message
	    )
	    
		try
		{
            if ( "$script:logFilePath" -eq "" )
            {
                $workingDirectory = Get-WorkingDirectory
                if ( $workingDirectory -eq $false ) { $workingDirectory = "$env:USERPROFILE\Desktop" }
			    Set-Variable -Name logFilePath -Value "$workingDirectory\$(Get-ScriptBaseName)__$(Get-Date -Format yyyy-MM-dd__HH-mm-ss).log" -Scope script
            }
			$Message | Out-File -FilePath "$logFilePath" -Encoding ascii -Append
		}
		catch
		{
			if ( [Environment]::UserInteractive -eq $true -and -not ( $( get-process -Id $PID ).MainWindowHandle -eq 0 ) )
	        {
                write-host "ERROR : Failed to write log file." -ForegroundColor Red
            }
		}
    }
    #endregion

    # Assemble the string for CLI and logging
    if ( $CliUsesMessageOnly -eq $true )
    { $cliMessage = "$message" }
    $message = "$(Get-Date -Format yyyy-MM-dd__HH-mm-ss)  |  $level  |  $message"
    if ( $CliUsesMessageOnly -eq $false )
    { $cliMessage = "$message" }
  
    try
    {
        if ( $cliOnly -eq $true ) { CLI-Writer -Message "$cliMessage" -Level $level }
        elseif ( $logOnly -eq $true ) { FILE-Writer -Message "$message" }
        else { FILE-Writer -Message "$message" ; CLI-Writer -Message "$cliMessage" -Level $level }
    }
    catch
    {
        # Suppress exceptions
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function unify-StringLength
{
    param (
            # The original string.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "The original string.")]
		    [String]$originalString,

            # The original string.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "The expected length of the string.")]
		    [int32]$expectedLength
          )

    $result = $null
    $result = $originalString

    while ( $result.Length -lt $expectedLength )
    {
        $result += " "
    }

    return $result
}
#==================================================================================================================================
#endregion
#region REGISTRY CONFIGURATION FUNCTIONS
##### REGISTRY CONFIGURATION FUNCTIONS
#----------------------------------------------------------------------------------------------------------------------------------
function get-registryItemPropertyType
{
    <#
		.NOTES
        Reduced
		Version=2.2
		MajorCompatibility=1.2
	#>

    param (
            # Provide the full path to the registry key which the property type should be obtained from.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Provide the full path to the registry key which the property type should be obtained from.")]
		    [string]$registryFullPath
    )
    
    $functionName = "$($MyInvocation.InvocationName) :"
    
    try
    {
        ### checking upfront if the registry key exists
        $registryFullPathSplit = $null
        $registryFullPathSplit = $registryFullPath -split "\\"
        # Data we need for the try-catch block
        $registryDrive = $null
        $registryDrive = $registryFullPathSplit[0]
        $registryParentKeyPath = $null
        $registryParentKeyPath = $registryFullPathSplit[1..($registryFullPathSplit.count-2)] -join '\'
        $keyName = $null
        $keyName = $registryFullPathSplit[-1]
    
        # Data we need for the check
        $registryFullParentKeyPath = $null
        $registryFullParentKeyPath = $registryFullPathSplit[0..($registryFullPathSplit.count-2)] -join '\'

        if ( "$registryDrive" -ieq "hkcu:" )
        {
            $driveName = "currentuser"
        }
        elseif ( "$registryDrive" -ieq "hklm:" )
        {
            $driveName = "localmachine"
        }
        elseif ( "$registryDrive" -ieq "hkcr:" )
        {
            $driveName = "ClassesRoot"
        }
        else
        {
            throw("$functionName this registry drive is not implemented yet.")
        }

        ### We can only get the data if the item exists
        $valueType = $null
        if ( -not ( "$keyName" -ieq "(Default)" ) )
        {
            if ( Get-ItemProperty -Path "$registryFullParentKeyPath" -Name "$keyName" -ErrorAction SilentlyContinue ) 
            {
                try
                {
                    $reg = $null
                    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("$driveName",$ENV:COMPUTERNAME)
                    $valueType = $reg.OpenSubKey("$registryParentKeyPath").GetValueKind("$keyName")
                    $reg.close()
                }
                catch
                {
                    throw("$functionName Error occured gathering information. This is the last error-message: '$($_.exception.message)'.")
                }
            }
        }
        else
        {
            # Default keys are always regsz = string
            $valueType = "String"
        }

        return $valueType
    }
    catch
    {
        LOG-Writer -Message "$($_.exception.message)" -Level DEBUG -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function registryValue
{
    <#
		.NOTES
        Reduced
		Version=2.4
		MajorCompatibility=1.0

        Downstream-Dependencies:
        - get-registryItemPropertyType
	#>

    param (
            # Specify the full path.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Specify the full path.")]
            [ValidateNotNullOrEmpty()]
		    [string]$registryFullPath,

            # Specify the value for the registry key.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Specify the value for the registry key.")]
		    [string]$registryKeyValue,

            # Specify the type of the registry key. Valid values are 'DWORD', 'String', 'Binary', 'ExpandString', 'MultiString' and 'QWord'. Defaults to 'DWORD'.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Specify the type of the registry key. Valid values are 'DWORD', 'String', 'Binary', 'ExpandString', 'MultiString' and 'QWord'. Defaults to 'DWORD'.")]
		    [ValidateSet('DWORD','String','Binary','ExpandString','MultiString','QWord')]
            [string]$registryKeyType = "DWORD",

            # Specify the action to take. Valid values are 'create' and 'delete'.
            [parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Specify the action to take. Valid values are 'create' and 'delete'.")]
            [ValidateSet("create","delete")]
		    [string]$action
    )
    
    $functionName = "$($MyInvocation.InvocationName) :"
    
    try
    {
        # Splitting of the key name and preparing the values
        $registryFullPathSplit = $registryFullPath -split "\\"
        $registryParentKeyPath = $registryFullPathSplit[0..($registryFullPathSplit.count-2)] -join '\'
        $keyName = $null
        $keyName = $registryFullPathSplit[-1]

        ### Creating registry drive
        if ( $registryParentKeyPath.StartsWith("HKCR:\") -or $registryParentKeyPath.StartsWith("hkcr:\") )
        {
            if ( -not ( Get-PSDrive -name HKCR -ErrorAction SilentlyContinue ) )
            {
                $result = $null
                $result = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -ErrorAction Stop
            }
        }

        if ( "$action" -ieq "create" )
        {
            # Checking if the parent Path is existent
            if ( -not ( Test-Path "$registryParentKeyPath" -ErrorAction SilentlyContinue ) )
            {
                $result = $null
                $result = New-Item -Path "$registryParentKeyPath" -ItemType directory -Force -ErrorAction SilentlyContinue
                if ( Get-Item -Path "$registryParentKeyPath" -ErrorAction SilentlyContinue )
                {
                    # Success
                }
                else
                {
                    throw("$functionName Failed to create the parent path. This is the last error-message '$($error[0])'.")
                }
            }

            # Getting the data type of the key
            # if the key is there
            if ( Get-ItemProperty "$registryParentKeyPath" -Name "$keyName" -ErrorAction SilentlyContinue ) 
            {
                $valueType = $null
                $valueType = get-registryItemPropertyType -registryFullPath "$registryFullPath"

                if ( $valueType -eq $false )
                {
                    throw("$functionName Valuetype not determined. Can´t continue.")
                }
            }

            # deleting the key if necessary (data type not correct)
            if ( -not ( "$valueType" -eq "" ) )
            {
                if ( -not ( "$valueType" -ieq "$registryKeyType" ) )
                {
                        
                    $result = $null
                    $result = Remove-ItemProperty -Path "$registryParentKeyPath" -Name "$keyName" -ErrorAction stop
                    if ( -not ( Get-ItemProperty -Path "$registryParentKeyPath" -Name "$keyName" -ErrorAction SilentlyContinue ) )
                    {
                        # Success
                    }
                    else
                    {
                        throw("$functionName Failed to delete the key. This is the last error-message '$($error[0])'.")
                    }
                }
            }

            # Checking if the key exists
            if ( -not ( Get-ItemProperty "$registryParentKeyPath" -Name "$keyName" -ErrorAction SilentlyContinue ) )
            {
                $result = $null
                $result = New-ItemProperty -Path "$registryParentKeyPath" "$keyName" -Value "" -PropertyType "$registryKeyType" -ErrorAction Stop
            }

            # Setting the key
            $result = $null
            $result = Set-ItemProperty -Path "$registryParentKeyPath" -Name "$keyName" -Value $registryKeyValue -ErrorAction Stop
        }
        elseif ( "$action" -ieq "delete" )
        {
            $result = $null
            $result = Remove-ItemProperty -Path "$registryParentKeyPath" "$keyName" -Force -ErrorAction Stop
        }
        
        ### Removing the registry drive
        if ( $registryParentKeyPath.StartsWith("HKCR:\") -or $registryParentKeyPath.StartsWith("hkcr:\") )
        {
            if ( Get-PSDrive -name HKCR -ErrorAction SilentlyContinue )
            {
                $result = $null
                $result = Remove-PSDrive -Name HKCR -ErrorAction Stop
            }
        }

        return $true
    }
    catch
    {
        LOG-Writer -Message "$($_.exception.message)" -Level DEBUG -CliUsesMessageOnly 
        return $false
    }
}
#==================================================================================================================================
#endregion
#region NIC CONFIGURATION FUNCTIONS
##### NIC CONFIGURATION FUNCTIONS
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NIC
{
    # This function is called by the interactive mode as well as 'configure-NICs' function.
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Is DataCore Software installed?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Is DataCore Software installed?")]
		    [boolean]$dcsInstalled,

            # Should default values of an adapter be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults,

            # Should the global default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should the global default values be restored?")]
		    [boolean]$includeGlobalSettings
          )
    
    $configError = $false

    try
    {
        LOG-Writer -Message "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" -Level VERBO -CliUsesMessageOnly 
        
        #region GLOBAL SETTINGS
        ### Ensure PowerPlan is set to High Performance
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-PowerPlan -restoreDefaults $includeGlobalSettings
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### Global LMHOSTS Lookup
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-LmHostsLookup -restoreDefaults $includeGlobalSettings
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### Ensure that the standard nettransportfilter for port 3260 is available.
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-NetTransportFilter -Port 3260 -restoreDefaults $includeGlobalSettings
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }
        
        ### NetTransportFilter specific / custom ports - this is considered to be a global setting even if dependent on the NIC / DCS Targetport or iSCSI-Connection!
        if ( $configError -eq $false )
        {
            if ( $dcsInstalled -eq $true )
            {
                $dcsPortObjects = $null
                $dcsPortObjects = Get-DcsPort -Type iSCSI -MachineType Servers -Machine $( Get-DcsServer -Server $(hostname) -ErrorAction Stop ) -ErrorAction Stop | where { $_.idinfo.connectionname -ieq $( $adapterObject.name ) }
                $tcpPorts = $null
                $tcpPorts = @( $dcsPortObjects.PortConfigInfo.PortalsConfig.tcpport | Select-Object -Unique )
                foreach ( $tcpPort in $tcpPorts )
                {
                    $result = $null
                    $result = configure-NetTransportFilter -Port $tcpPort -restoreDefaults $includeGlobalSettings
                    if ( $result -eq $false )
                    {
                        $configError = $true
                        break
                    }
                }
            }
            
            # Additionally we check existing iSCSI-Connections if there are special-ports being used.
            $iScsiConnections = $null
            $iScsiConnections = Get-IscsiConnection -ErrorAction SilentlyContinue
            if ( $iScsiConnections )
            {
                $tcpPorts = $null
                $tcpPorts = @( $iScsiConnections.TargetPortNumber | Select-Object -Unique )
                foreach ( $tcpPort in $tcpPorts )
                {
                    $result = $null
                    $result = configure-NetTransportFilter -Port $tcpPort -restoreDefaults $includeGlobalSettings
                    if ( $result -eq $false )
                    {
                        $configError = $true
                        break
                    }
                }
            }
        }

        ### Configuring the NetTcpSettings
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-NetTcpSettings -restoreDefaults $includeGlobalSettings
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }
        #endregion



        #region ADAPTER SETTINGS
        ### Ensure that the adapter is enabled
        if ( $configError -eq $false )
        {
            if ( $adapterObject.Status -ieq "disabled" )
            {
                $result = $null
                $result = Enable-NetAdapter -InputObject $adapterObject -ErrorAction Stop
                LOG-Writer -Message "Netadapter '$( $adapterObject.name )' was enabled because it was previous in disabled state." -Level WARNI -CliUsesMessageOnly 
            }
            sleep 3
        }
        
        ### Netadapter Bindings
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-NetadapterBindings -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### RSC
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-RSC -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### RSS
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-RSS -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### Nagle and Delayed Ack configuration
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-NagleAndDelayedAck -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### WINS configuration
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-WinsLookup -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### DNS registration configuration
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-DnsRegistration -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### SRIOV configuration
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-SRIOV -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### Netadapter Powersaving configuration
        if ( $configError -eq $false )
        {
            $result = $null
            $result = configure-NetAdapterPowerSaving -adapterObject $adapterObject -restoreDefaults $restoreDefaults
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }

        ### Restarting the adapter to enforce settings
        if ( $configError -eq $false )
        {
            $result = $null
            $result = Restart-NetAdapter -adapterObject $adapterObject
            if ( $result -eq $false )
            {
                $configError = $true
            }
        }
        #endregion



        ### Result for this NIC
        if ( $configError -eq $false )
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch
    {
        LOG-Writer -Message "Failed to configure the netadapter '$( $adapterObject.name )'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NICs
{
    # This function is used by parameters 'NetAdapters' and 'adapterIdentifier'
    param (
            # Please provide the adapter object which should be configured.
            [parameter(ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adaptersToConfigure,

            # Is DataCore Software installed?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Is DataCore Software installed?")]
		    [boolean]$dcsInstalled,

            # Should default values of an adapter be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults,

            # Should the global default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should the global default values be restored?")]
		    [boolean]$includeGlobalSettings
          )
    
    $configError = $false

    try
    {
        # Go through the adapters
        if ( $adaptersToConfigure )
        {
            $continue = $true 

            ### plausibility check that we don´t configure all adapters in the system.
            $allAdapters = $null
            $allAdapters = Get-NetAdapter -ErrorAction SilentlyContinue
            
            if ( $adaptersToConfigure.Count -ge $allAdapters.count )
            {
                $message = "All NICs in the system have been chosen to get iSCSI settings applied. At least one adapter should remain for non-iSCSI traffic. Please re-consider your string passed to 'NetAdapters' or 'adapterIdentifier' parameter."
                LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
                throw("$message")
            }
                        
            LOG-Writer -Message "These are the detected adapters:" -Level INFOR -CliUsesMessageOnly
            foreach ( $object in $adaptersToConfigure )
            {
                $message = "--> $($object.Name)"
                LOG-Writer -Message "$message" -Level INFOR -CliUsesMessageOnly
                $message = "    Details: $( $object.interfaceDescription ), $( $object.MacAddress ), $( $object.LinkSpeed )"
                LOG-Writer -Message "$message" -Level INFOR -CliUsesMessageOnly
            }

            if ( $sessionIsInteractive -eq $true -and $Force -eq $false )
            {
                $1answer = $null
                $1answer = read-host -Prompt "Would you like to continue configuring adapter(s) (Y/N)?"
                if ( -not ( $1answer -ieq "y" ) )
                {
                    $continue = $false
                }
                else
                {
                    LOG-Writer -Message "Received user confirmation." -Level DEBUG -LogOnly
                }
            }
            else
            {
                LOG-Writer -Message "Session non-interactive or force-flag was used. Skipping user confirmation." -Level DEBUG -LogOnly
            }

            if ( $continue -eq $true )
            {
                $configError = $false

                foreach ( $object in $adaptersToConfigure )
                {
                    $result = $null
                    $result = configure-NIC -dcsInstalled $dcsInstalled -adapterObject $object -restoreDefaults $restoreDefaults -includeGlobalSettings $includeGlobalSettings
                    if ( $result -eq $false )
                    {
                        $configError = $true
                        # break the inner loop
                        break
                    }
                }

                LOG-Writer -Message " " -Level INFOR -CliOnly -CliUsesMessageOnly
                if ( $configError -eq $false )
                {
                    $message = "No errors have been detected during configuration loop."
                    LOG-Writer -Message "$message" -Level SUCCE -CliUsesMessageOnly
                }
                else
                {
                    $message = "Something went wrong through the configuration loop. Please check the output."
                    LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
                }
            }
        }
        else
        {
            $message = "No adapter(s) found with adapterIdentifier '$adapterIdentifier'."
            LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
        }



        ### Result
        if ( $configError -eq $false )
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    catch
    {
        LOG-Writer -Message "Failed to configure the netadapters. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
#region NIC CONFIGURATION FUNCTIONS HELPER FUNCTIONS
### NIC CONFIGURATION FUNCTIONS HELPER FUNCTIONS
#----------------------------------------------------------------------------------------------------------------------------------
function configure-DnsRegistration
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        if ( Get-DnsClient -InterfaceAlias "$( $adapterObject.name )" -ErrorAction SilentlyContinue )
        {
            try
            {
                $result = $null
                if ( $restoreDefaults -eq $false )
                {
                    $action = "Disabling"
                    $result = Set-DnsClient -InterfaceAlias "$( $adapterObject.name )" -RegisterThisConnectionsAddress $false -ErrorAction Stop
                }
                else
                {
                    $action = "Enabling"
                    $result = Set-DnsClient -InterfaceAlias "$( $adapterObject.name )" -RegisterThisConnectionsAddress $true -ErrorAction Stop
                }
                
                LOG-Writer -Message "'$action' DNS registration on adapter '$( $adapterObject.name )' successful." -Level SUCCE -CliUsesMessageOnly
            }
            catch
            {
                $message = "Failed to configure DNS registration settings on adapter '$( $adapterObject.name )'. This is the last errormessage: '$($_.exception.message)'."
                LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
                Throw($message)
            }
        }
        else
        {
            LOG-Writer -Message "Skipping DNS-Client configuration as no entry was found on adapter '$( $adapterObject.name )'." -Level VERBO -CliUsesMessageOnly
        }
                
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure DNS registration settings. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-LmHostsLookup
{
    param (
            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        
        $wmiClassObject = $null
        $wmiClassObject = [wmiclass]'Win32_NetworkAdapterConfiguration'
            
        $result = $null
        if ( $restoreDefaults -eq $false )
        {
            $action = "Disabling"
            $result = $wmiClassObject.enablewins($false,$false)
        }
        else
        {
            $action = "Enabling"
            $result = $wmiClassObject.enablewins($true,$true)
        }
        
        if ( $result.returnvalue -eq 0 )
        {
            LOG-Writer -Message "'$action' LMHOSTS lookup successful." -Level SUCCE -CliUsesMessageOnly 
        }
        elseif ( $result.returnvalue -eq 1 )
        {
            LOG-Writer -Message "'$action' LMHOSTS lookup successful, but a reboot is required." -Level WARNI -CliUsesMessageOnly 
        }
        elseif ( $result.returnvalue -eq 100 )
        {
            LOG-Writer -Message "WARNING: '$action' LMHOSTS lookup not possible as DHCP is enabled on adapter. You need to configure the 'LMHOSTS Lookup' value manually." -Level WARNI -CliUsesMessageOnly 
            $warningOccured = $true
        }
        else
        {
            $message = "'$action' LMHOSTS lookup failed. Return-Code is '$($result.returnvalue)'. See 'https://msdn.microsoft.com/en-us/library/aa390384(v=vs.85).aspx' for more information."
            LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly 
            Throw($message)
        }

        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure the LMHOSTS lookup. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NagleAndDelayedAck
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        $deviceId = $null
        $deviceId = $adapterObject.DeviceID

        if ( $restoreDefaults -eq $false )
        {
            $action = "Disabling"
            # TcpAckFrequency
            $item = "TcpAckFrequency"
            if ( -not ( registryValue -registryFullPath "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$deviceId\TcpAckFrequency" -registryKeyValue "1" -registryKeyType "DWORD" -action "create" ))
            {
                $message = "'$action' '$item' on adapter '$( $adapterObject.Name )' failed."
                LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
                throw($message)
            }
            else
            {
                LOG-Writer -Message "'$action' '$item' on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly
            }

            # TcpNoDelay
            $item = "TcpNoDelay"
            if ( -not ( registryValue -registryFullPath "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$deviceId\TcpNoDelay" -registryKeyValue "1" -registryKeyType "DWORD" -action "create" ) )
            {
                $message = "'$action' '$item' on adapter '$( $adapterObject.Name )' failed."
                LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
                throw($message)
            }
            else
            {
                LOG-Writer -Message "'$action' '$item' on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly
            }
        }
        else
        {
            $action = "Enabling"
            # TcpAckFrequency
            $item = "TcpAckFrequency"
            if ( -not ( registryValue -registryFullPath "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$deviceId\TcpAckFrequency" -action "delete" ))
            {
                $message = "'$action' '$item' on adapter '$( $adapterObject.Name )' failed."
                LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
                throw($message)
            }
            else
            {
                LOG-Writer -Message "'$action' '$item' on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly
            }

            # TcpNoDelay
            $item = "TcpNoDelay"
            if ( -not ( registryValue -registryFullPath "HKLM:\system\currentcontrolset\services\tcpip\parameters\interfaces\$deviceId\TcpNoDelay" -action "delete" ) )
            {
                $message = "'$action' '$item' on adapter '$( $adapterObject.Name )' failed."
                LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
                throw($message)
            }
            else
            {
                LOG-Writer -Message "'$action' '$item' on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly
            }
        }
        
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure NagleAndDelayedAck. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NetAdapterBindings
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        $excludeBindings = @()
        $excludeBindings = @(
                                "ms_tcpip"   # TCP IPv4
                                "vms_pp"     # Hyper-V extensible switch
                                "ms_implat"  # Microsoft Network Adapter Multiplexor Protocol
                            )
        
        $netAdapterProtocols = $null
        $netAdapterProtocols = Get-NetAdapterBinding -Name "$( $adapterObject.name )" -ErrorAction stop
        if ( $restoreDefaults -eq $false )
        {
            foreach ( $boundProtocol in $netAdapterProtocols )
            {
                if ( $boundProtocol.Enabled -eq $false )
                {
                    LOG-Writer -Message "'$($boundProtocol.componentid)' already disabled on adapter '$( $adapterObject.name )'." -Level VERBO -CliUsesMessageOnly 
                }
                else
                {
                    if ( $excludeBindings -icontains $( $boundProtocol.componentid ) )
                    {
                        LOG-Writer -Message "'$($boundProtocol.componentid)' is skipped on adapter '$( $adapterObject.name )'." -Level VERBO -CliUsesMessageOnly 
                    }
                    else
                    {
                        try
                        {
                            $result = $null
                            $result = Disable-NetAdapterBinding -Name "$( $adapterObject.name )" -ComponentID "$($boundProtocol.componentid)" -ErrorAction Stop
                            LOG-Writer -Message "'$($boundProtocol.componentid)' successfully disabled on adapter '$( $adapterObject.name )'." -Level SUCCE -CliUsesMessageOnly 
                        }
                        catch
                        {
                            $message = "Failed to disable protocol '$($boundProtocol.componentid)' on adapter '$( $adapterObject.name )'."
                            LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly 
                            throw($message)
                        }
                    }
                }
            }
        }
        else
        {
            LOG-Writer -Message "Enabling all protocols on '$( $adapterObject.name )'." -Level INFOR -CliUsesMessageOnly 
            foreach ( $boundProtocol in $netAdapterProtocols )
            {
                if ( $boundProtocol.Enabled -eq $true )
                {
                    LOG-Writer -Message "'$($boundProtocol.componentid)' already enabled on adapter '$( $adapterObject.name )'." -Level SUCCE -CliUsesMessageOnly 
                }
                else
                {
                    try
                    {
                        $result = $null
                        $result = Enable-NetAdapterBinding "$( $adapterObject.name )" -ComponentID "$($boundProtocol.componentid)" -ErrorAction Stop
                        LOG-Writer -Message "'$($boundProtocol.componentid)' successfully enabled on adapter '$( $adapterObject.name )'." -Level SUCCE -CliUsesMessageOnly 
                    }
                    catch
                    {
                        $message = "Failed to enable protocol '$($boundProtocol.componentid)' on adapter '$( $adapterObject.name )'."
                        LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly 
                        throw($message)
                    }
                }
            }
        }
        
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure adapter bindings. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NetAdapterPowerSaving
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        if ( $restoreDefaults -eq $false )
        {
            $action = "Disabling"
            $value = 1
        }
        else
        {
            $action = "Enabling"
            $value = 2
        }

        $strComputer = "."
        $objWMi = Get-WmiObject -namespace root\StandardCimv2 -computername localhost -Query "Select * from MSFT_NetAdapterPowerManagementSettingData" -ErrorAction Stop | where { $_.name -ieq "$( $adapterObject.name )" }
        # Disable = 1, enable = 2
        if ( $objWMi )
        {
            if ( $objWMi.AllowComputerToTurnOffDevice -eq $value )
            {
                LOG-Writer -Message "Skipping '$($action.toLower())' powersaving functionality on adapter '$( $adapterObject.Name )' as it is already set." -Level VERBO -CliUsesMessageOnly 
            }
            else
            {
                $objWMi.AllowComputerToTurnOffDevice=$value
                $result = $objWMi.Put()
                LOG-Writer -Message "'$action' powersaving functionality on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly 
            }
        }
        else
        {
            LOG-Writer -Message "WARNING: Skipping '$($action.toLower())' powersaving functionality on adapter '$( $adapterObject.Name )' as no WMI object was found." -Level WARNI -CliUsesMessageOnly 
        }
                
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure netadapter power settings on adapter '$( $adapterObject.Name )'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NetTcpSettings
{
    param (
            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    # Filter configuration
    if ( $restoreDefaults -eq $false )
    {
        $action = "Setting"

        # Currently the settings are equivalent to the default-settings.
        $SettingName                = "DatacenterCustom"
        $DelayedAckFrequency        = 1
        $DelayedAckTimeoutMs        = 10
        $CongestionProvider         = "DCTCP"
        $CwndRestart                = 1
        $InitialCongestionWindowMss = 4
        $ScalingHeuristics          = 1
        $Timestamps                 = 1
        $AutoTuningLevelLocal       = "Normal"
        $EcnCapability              = 1
        $InitialRtoMs               = 3000
        $MinRtoMs                   = 20
        $NonSackRttResiliency       = 0
        $MaxSynRetransmissions      = 2
    }
    else
    {
        $action = "Defaulting"

        $SettingName                = "DatacenterCustom"
        $DelayedAckFrequency        = 1
        $DelayedAckTimeoutMs        = 10
        $CongestionProvider         = "DCTCP"
        $CwndRestart                = 1
        $InitialCongestionWindowMss = 4
        $ScalingHeuristics          = 1
        $Timestamps                 = 1
        $AutoTuningLevelLocal       = "Normal"
        $EcnCapability              = 1
        $InitialRtoMs               = 3000
        $MinRtoMs                   = 20
        $NonSackRttResiliency       = 0
        $MaxSynRetransmissions      = 2
    }
    
    try
    {
        $result = $null
        $result = Set-NetTCPSetting -SettingName $SettingName `
                                    -DelayedAckFrequency $DelayedAckFrequency `
                                    -DelayedAckTimeoutMs $DelayedAckTimeoutMs `
                                    -CongestionProvider $CongestionProvider `
                                    -CwndRestart $CwndRestart `
                                    -InitialCongestionWindowMss $InitialCongestionWindowMss `
                                    -ScalingHeuristics $ScalingHeuristics `
                                    -Timestamps $Timestamps `
                                    -AutoTuningLevelLocal $AutoTuningLevelLocal `
                                    -EcnCapability $EcnCapability `
                                    -InitialRtoMs $InitialRtoMs `
                                    -MinRtoMs $MinRtoMs `
                                    -NonSackRttResiliency $NonSackRttResiliency `
                                    -MaxSynRetransmissions $MaxSynRetransmissions -ErrorAction Stop
        LOG-Writer -Message "'$action' NetTcpSettings for '$SettingName' successful." -Level SUCCE -CliUsesMessageOnly
        
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to set NetTcpSettings for '$SettingName'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-NetTransportFilter
{
    param (
            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Provide the Port for the desired Nettransportfilter.")]
		    [Int32]$Port,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )

    try
    {
        $filterExists = $false
        if ( Get-NetTransportFilter -LocalPortStart $Port -ErrorAction SilentlyContinue )
        {
            $filterExists = $true
        }

        ### CONFIGURATION
        if ( $restoreDefaults -eq $false )
        {
            if ( $filterExists -eq $false )
            {
                try
                {
                    $result = $null
                    $result = New-NetTransportFilter -SettingName Datacenter -LocalPortStart $Port -LocalPortEnd $Port -RemotePortStart 0 -RemotePortEnd 65535 -ErrorAction Stop
                    LOG-Writer -Message "Creating NetTransportFilter with local port '$Port' successful." -Level SUCCE -CliUsesMessageOnly 
                }
                catch
                {
                    $message = "Failed to create NetTransportFilter with local port '$Port'."
                    LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly 
                    throw($message)
                }
            }
            else
            {
                LOG-Writer -Message "NetTransportFilter with local port '$Port' already exists." -Level VERBO -CliUsesMessageOnly 
            }
        }
        ### REMOVAL
        else
        {
            if ( $filterExists -eq $false )
            {
                LOG-Writer -Message "NetTransportFilter with local port '$Port' already removed / not existing." -Level SUCCE -CliUsesMessageOnly 
            }
            else
            {
                try
                {
                    $result = $null
                    $result = Remove-NetTransportFilter -SettingName Datacenter -LocalPortStart 3260 -LocalPortEnd 3260 -RemotePortStart 0 -RemotePortEnd 65535 -ErrorAction Stop -Confirm:$false
                    LOG-Writer -Message "Removal of NetTransportFilter with local port '$Port' successful." -Level SUCCE -CliUsesMessageOnly 
                }
                catch
                {
                    $message = "Failed to remove NetTransportFilter with local port '$Port'."
                    LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly 
                    throw($message)
                }
            }
        }

        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure the NetTransportfilter. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-PowerPlan
{
    param (
            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        #SET POWER PLAN TO HIGH PERFORMANCE OR RESET TO BALANCED
        if ( $restoreDefaults -eq $false )
        {
            $planName = "High performance"
            $planId = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
        }
        else
        {
            $planName = "Balanced"
            $planId = "381b4222-f694-41f0-9685-ff5bb260df2e"
        }

        # This does not work due to localization
        #$targetPlan = $null
        #$targetPlan = powercfg -l | % { if ($_.contains("$planName")) { $_.split()[3] } }

        powercfg -setactive "$planId"
        
        LOG-Writer -Message "Setting Windows Power Plan to '$planName' with ID '$planId' successful." -Level SUCCE -CliUsesMessageOnly 
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure the Power Plan. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-RSC
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        if ( $restoreDefaults -eq $false )
        {
		    if ( Get-NetAdapterRsc -Name "$( $adapterObject.name )" -ErrorAction SilentlyContinue )
		    {
                $result = $null
                $result = Set-NetAdapterRsc -Name "$( $adapterObject.name )" -IPv4Enabled 1 -IPv6Enabled 1 -ErrorAction Stop
			    LOG-Writer -Message "Configuration of RSC on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly 
		    }
		    else
		    {
                LOG-Writer -Message "Configuration of RSC on adapter '$( $adapterObject.Name )' will be skipped as RSC is not available." -Level VERBO -CliUsesMessageOnly 
		    }
        }
        else
        {
            LOG-Writer -Message "WARNING: Configuration of RSC on adapter '$( $adapterObject.Name )' will be skipped." -Level WARNI -CliUsesMessageOnly 
        }
    }
    catch
    {
        LOG-Writer -Message "Failed to configure RSC on adapter '$( $adapterObject.Name )'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-RSS
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        if ( $restoreDefaults -eq $false )
        {
		    if ( Get-NetAdapterRss -Name "$( $adapterObject.name )" -ErrorAction SilentlyContinue )
		    {
                $result = $null
                $result = Set-NetAdapterRss -Name "$( $adapterObject.name )" -Enabled 1 -ErrorAction Stop
                LOG-Writer -Message "Configuration of RSS on adapter '$( $adapterObject.Name )' successful." -Level SUCCE -CliUsesMessageOnly 
		    }
		    else
		    {
			    LOG-Writer -Message "Configuration of RSS on adapter '$( $adapterObject.Name )' will be skipped as RSS is not available." -Level VERBO -CliUsesMessageOnly 
		    }
        }
        else
        {
            LOG-Writer -Message "WARNING: Configuration of RSS on adapter '$( $adapterObject.Name )' will be skipped." -Level WARNI -CliUsesMessageOnly 
        }
    }
    catch
    {
        LOG-Writer -Message "Failed to configure RSS on adapter '$( $adapterObject.Name )'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-SRIOV
{
    # Version 1.1

    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    try
    {
        $vmSwitchIsIoV = $( get-vmSwitch -erroraction Stop | where { $_.NetAdapterInterfaceDescription -ieq $adapterObject.InterfaceDescription } ).IovEnabled
    }
    catch
    {
        $vmSwitchIsIoV = $false
    }

    try
    {
        if ( $vmSwitchIsIoV -ieq $true )
        {
            $message = "Adapter '$( $adapterObject.name )' is attached to a vSwitch with IOV enabled. Skipping modification of SRIOV setting."
            LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly 
            $currentSRIOVSettings = $null
            $currentSRIOVSettings = Get-NetAdapterSriov -Name $( $adapterObject.name ) -ErrorAction Stop
            if ( $currentSRIOVSettings.Enabled -eq $false )
            {
                LOG-Writer -Message "SRIOV IS DISABLED ON ADAPTER. That indicates a misconfiguration. Please check!" -Level WARNI -CliUsesMessageOnly 
            }
        }
        else
        {
            if ( get-netadaptersriov -name "$( $adapterObject.name )" -ErrorAction SilentlyContinue )
            {
                try
                {
                    $result = $null
                    if ( $restoreDefaults -eq $false )
                    {
                        $action = "Disabling"
                        $result = get-netadaptersriov -name "$( $adapterObject.name )" -ErrorAction Stop | Disable-NetAdapterSriov -ErrorAction Stop
                    }
                    else
                    {
                        $action = "Enabling"
                        $result = get-netadaptersriov -name "$( $adapterObject.name )" -ErrorAction Stop | Enable-NetAdapterSriov -ErrorAction Stop
                    }

                    LOG-Writer -Message "'$action' SRIOV on adapter '$( $adapterObject.name )' successful." -Level SUCCE -CliUsesMessageOnly
                }
                catch
                {
                    $message = "Failed to '$($action.tolower)' SRIOV settings on adapter '$( $adapterObject.name )'. This is the last errormessage: '$($_.exception.message)'."
                    LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly 
                    throw($message)
                }
            }
            else
            {
                LOG-Writer -Message "SRIOV configuration skipped on adapter '$( $adapterObject.name )' as no instance was found." -Level VERBO -CliUsesMessageOnly 
            }
        }
                
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure SRIOV settings on adapter '$( $adapterObject.name )'. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------
function configure-WinsLookup
{
    param (
            # Please provide the adapter object which should be configured.
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Please provide the adapter object which should be configured.")]
		    $adapterObject,

            # Should default values be restored?
            [parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Should default values be restored?")]
		    [boolean]$restoreDefaults
          )
    
    try
    {
        if ( $restoreDefaults -eq $false )
        {
            $EthernetNetbiosNameLookup = "disabled"
        }
        else
        {
            $EthernetNetbiosNameLookup = "default"
        }
        
        $deviceIndex = $null
        $deviceIndex = $adapterObject.ifIndex
        $wmiObject = $null
        $wmiObject = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction Stop | where { $_.InterfaceIndex -eq $deviceIndex }
        if ( $wmiObject )
        {
            $result = $null
            # setting the value
            if ( "$EthernetNetbiosNameLookup" -ieq "default" )
            {
                $result = $wmiObject.SetTcpipNetbios(0)
            }
            elseif ( "$EthernetNetbiosNameLookup" -ieq "enabled" )
            {
                $result = $wmiObject.SetTcpipNetbios(1)
            }
            elseif ( "$EthernetNetbiosNameLookup" -ieq "disabled" )
            {
                $result = $wmiObject.SetTcpipNetbios(2)
            }
                            
            if ( $result.returnvalue -eq 0 )
            {
                LOG-Writer -Message "WINS lookup successfully configured to '$EthernetNetbiosNameLookup' on adapter '$( $adapterObject.name )'." -Level SUCCE -CliUsesMessageOnly
            }
            elseif ( $result.returnvalue -eq 1 )
            {
                LOG-Writer -Message "WINS lookup successfully configured to '$EthernetNetbiosNameLookup' on adapter '$( $adapterObject.name )', but a reboot is required." -Level WARNI -CliUsesMessageOnly
            }
            elseif ( $result.returnvalue -eq 84 )
            {
                LOG-Writer -Message "WINS lookup cant be configured to '$EthernetNetbiosNameLookup' on adapter '$( $adapterObject.name )' as no IP-address is assigned." -Level WARNI -CliUsesMessageOnly
            }
            elseif ( $result.returnvalue -eq 100 )
            {
                LOG-Writer -Message "WARNING: DHCP not enabled on adapter '$( $adapterObject.name )'. You need to configure the WINS lookup to '$EthernetNetbiosNameLookup' value manually." -Level WARNI -CliUsesMessageOnly
            }
            else
            {
                $message = "Failed to configure WINS on adapter '$( $adapterObject.name )'. Return-Code is '$($result.returnvalue)'. See 'https://msdn.microsoft.com/en-us/library/aa393601(v=vs.85).aspx' for more information."
                LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
                throw($message)
            }
        }
        else
        {
            $message = "$functionName Could not find WMI object."
            LOG-Writer -Message $message -Level ERROR -CliUsesMessageOnly
            throw($message)
        }
                
        return $true
    }
    catch
    {
        LOG-Writer -Message "Failed to configure WINS. This is the last errormessage: '$($_.exception.message)'." -Level ERROR -CliUsesMessageOnly 
        return $false
    }
}
#----------------------------------------------------------------------------------------------------------------------------------

#endregion
#endregion
#endregion





#region INITIALIZATION
$scriptVersion = "3.9"
$dcsColor = "Cyan"
$msiscsiColor = "DarkCyan"

# Check if we have an userinteractive session
if ( [Environment]::UserInteractive -eq $true -and -not ( $(get-process -Id $PID).MainWindowHandle -eq 0 ) )
{
    $sessionIsInteractive = $true
}
else
{
    $sessionIsInteractive = $false
}

# check the OS
$osObject = $null
$osObject = Get-WmiObject win32_operatingsystem -ErrorAction SilentlyContinue
$osNameString = $null
$osNameString = $osObject.name
$installedOS = $null
if ( $osNameString -imatch "2008" )
{
    $installedOS = "2008"
}
elseif ( $osNameString -imatch "2012" )
{
    $installedOS = "2012"
}
elseif ( $osNameString -imatch "2012R2" )
{
    $installedOS = "2012"
}
elseif ( $osNameString -imatch "2016" )
{
    $installedOS = "2016"
}
elseif ( $osNameString -imatch "2019" )
{
    $installedOS = "2019"}
else
{
    $installedOS = $false
}

### Check if DataCore Software is installed
$dcsInstalled = $true
# Step 1 - if we have no registry key - then this is an indication
$bpKey = 'BaseProductKey'
$regKey = Get-Item "HKLM:\Software\DataCore\executive" -ErrorAction SilentlyContinue
if ( $regKey )
{
    $strProductKey = $regKey.getValue($bpKey)
    $regKey = Get-Item "HKLM:\$strProductKey" -ErrorAction SilentlyContinue
    if ( $regKey )
    {
        $installPath = $regKey.getValue('InstallPath')
    }
    else
    {
        $dcsInstalled = $false
    }
}
else
{
    $dcsInstalled = $false
}
# Step 2 - Check for DCSX service
if ( -not ( get-service -name DCSX -ErrorAction SilentlyContinue ) )
{
     $dcsInstalled = $false
}
# Step 3 - Check if DCSX service is running
if ( -not ( ( get-service -name DCSX -ErrorAction SilentlyContinue ).Status -ieq "running" ) )
{
     $dcsInstalled = $false
}
#endregion





#region MAIN
LOG-Writer -Message "Script started" -Level DEBUG -LogOnly

### PERMISSION CHECK - ELEVATED SHELL NEEDED
try
{
    $identity = $null
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = $null
    $principal = New-Object Security.Principal.WindowsPrincipal $identity
    $shellIsElevated = $null
    $shellIsElevated = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    if ( $shellIsElevated -eq $false )
    {
        $message = "Insufficient permissions. This needs to be run in an elevated/administrative PowerShell session."
        LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
        throw("$message")
    }
}
catch
{
    $message = "Error occured checking permissions. This is the last errormessage: '$( $_.exception.message )'."
    LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
    throw("$message")
}

### If DataCore Software is installed, load cmdlets and connect.
if ( $dcsInstalled -eq $true )
{
    if ( $( load-DcsCmdlets ) -eq $true )
    {
        #successfully loaded
        if ( $( dcsx-connection -action connect ) -eq $true )
        {
            LOG-Writer -Message "Successfully connected to DCSX service." -Level INFOR -LogOnly
        }
        else
        {
            LOG-Writer -Message "Failed to connect to DCSX through function call." -Level ERR -CliUsesMessageOnly
            $dcsInstalled = $false
        }
    }
    else
    {
        LOG-Writer -Message "Failed to load DataCore PowerShell through function call." -Level ERR -CliUsesMessageOnly
        $dcsInstalled = $false
    }
}

### The main work happens here.
if ( $installedOS -eq "2012" -or $installedOS -eq "2016" -or $installedOS -eq "2019" )
{
    if ( $sessionIsInteractive -eq $true -and "$NetAdapters" -eq "" -and "$adapterIdentifier" -eq "" )
    {
        if ( $($Host.Name) -inotmatch "ISE Host" )
        {
            #### Size of the window
            LOG-Writer -Message "Adjusting PowerShell windows size." -Level DEBUG -LogOnly
            ### PS Window
            $pswindow = $Host.ui.rawui
        
            ### we need to adjust the buffer
            try
            {
                $newsize = $pswindow.buffersize
                $newsize.height = 1200
                $newsize.width = 200
                $pswindow.buffersize = $newsize
            }
            catch
            {
                # Do nothing
                # This may go "boom" on a 2016 server when the resolution of the screen is too low.
            }

            ### and of course the window size itself.
            try
            {
                $newsize = $pswindow.windowsize
                $newsize.height = 80
                $newsize.width = 200
                $pswindow.windowsize = $newsize
            }
            catch
            {
                # Do nothing
                # This may go "boom" on a 2016 server when the resolution of the screen is too low.
            }
        }

        ### Write a header
        clear
        $message = "DataCore iSCSI Port Settings Script Version '$scriptVersion'"
        write-host "==========================================================="
        LOG-Writer -Message "$message" -Level INFOR -CliUsesMessageOnly
        write-host "==========================================================="
        

        $netadapterHashtable = @{}
        $netadapterHashtable = create-AdapterHashtable
        if ( $netadapterHashtable -eq $false )
        {
            $message = "Error creating adapter hashtable."
            LOG-Writer -Message "$message" -Level ERROR
            throw("$message")
        }
        elseif ( $netadapterHashtable.count -eq 0 )
        {
            $message = "WARNING: No adapters have been found. You may want to try the 'displayAll' directive."
            LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
        }

        ### Write some information about the display
        if ( $dcsInstalled -eq $true )
        {
            write-host "Note: Adapters identified as DataCore iSCSI target role (FE/MR) will be marked '$dcsColor'." -ForegroundColor $dcsColor
        }
        write-host "Note: Adapters identified as iSCSI Backend-Connection will be marked '$msiscsiColor'." -ForegroundColor $msiscsiColor
        write-host " " 
        write-host "The following adapters with IPv4 or IPv6 address have been discovered. If physical NICs"
        write-host "are used within teams or virtual switches only the corresponding team-interface or virtual"
        write-host "NICs are displayed. Settings will be applied to the physical NIC as well when vNIC is chosen."
                
        ### Display found adapters
        display-Adapters -netadapterHashtable $netadapterHashtable

        while ( $true )
        {
            write-host " " 
            write-host "Note: Use 'exit' to abort, 'display' to show the list of interfaces with IP-addresses or " -ForegroundColor Gray
            write-host "      'displayAll' for all interfaces detected." -ForegroundColor Gray
            if ( $restoreDefaults )
            {
                LOG-Writer -Message "Note: 'restoreDefaults' parameter provided. This sets adapter settings to default value." -Level WARNI -CliUsesMessageOnly
            }
            if ( $includeGlobalSettings )
            {
                LOG-Writer -Message "Note: 'includeGlobalSettings' parameter provided. This sets global settings to default value." -Level WARNI -CliUsesMessageOnly
            }
            $1answer = $null
            $1answer = Read-Host -Prompt "Please specify adapter IDs to modify as a comma separated list (Example: 1,4,5)"
            $message = "'$1answer' directive received from user."
            if ( $1answer -imatch "exit" )
            {
                LOG-Writer -Message "$message" -Level DEBUG -LogOnly
                break
            }
            elseif ( $1answer -imatch "displayAll" )
            {
                LOG-Writer -Message "$message" -Level DEBUG -LogOnly
                # Updating the hashtable
                $netadapterHashtable = @{}
                $netadapterHashtable = create-AdapterHashtable -all
                if ( $netadapterHashtable -eq $false )
                {
                    $message = "Error creating adapter hashtable (displayAll)."
                    LOG-Writer -Message "$message" -Level ERROR
                    throw("$message")
                }

                # Display found adapters
                LOG-Writer -Message "Displaying adapters discovered (displayAll)." -Level DEBUG -LogOnly
                display-Adapters -netadapterHashtable $netadapterHashtable
            }
            elseif ( $1answer -imatch "display" )
            {
                LOG-Writer -Message "$message" -Level DEBUG -LogOnly
                # Updating the hashtable
                $netadapterHashtable = @{}
                $netadapterHashtable = create-AdapterHashtable
                if ( $netadapterHashtable -eq $false )
                {
                    $message = "Error creating adapter hashtable (display)."
                    LOG-Writer -Message "$message" -Level ERROR
                    throw("$message")
                }

                # Display found adapters
                LOG-Writer -Message "Displaying adapters discovered (display)." -Level DEBUG -LogOnly
                display-Adapters -netadapterHashtable $netadapterHashtable
            }
            else
            {
                LOG-Writer -Message "Adapter selection '$1answer' received from user." -Level DEBUG -LogOnly
                $continue = $true

                # Remove trailing and starting blanks
                $1answer = $1answer.trim()
                # Replace blanks
                $1answer = $1answer -replace "\s+", ","
                $1answer = $1answer -replace ",+", ","
                # Transform into an array
                $array = @()
                $array = $1answer -split ","
                # Check if we have all referenced netadapters in the system which show up as elements in our hashtable
                foreach ( $element in $array )
                {
                    $value = $null
                    $value = $netadapterHashtable.get_item("$element")
                    if ( "$value" -eq "" )
                    {
                        $message = "ERROR: adapter '$element' is not existent. Please re-specify list of adapters."
                        LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
                        $continue = $false
                    }
                }
                
                # Doing the configuration of selected adapters.
                if ( $continue -eq $true )
                {
                    write-host "WARNING: Configuring adapters and their parents will experience a reset. This may cause service interuption." -ForegroundColor Yellow
                    if ( $force -eq $false )
                    {
                        $3answer = $null
                        $3answer = read-host -Prompt "Would you like to continue configuring adapter(s) with ID '$1answer' (Y/N)?"
                    }
                    else
                    {
                        $message = "Force configuration. Skipping user confirmation."
                        LOG-Writer -Message "$message" -Level VERBO -CliUsesMessageOnly
                    }
                    if ( $3answer -ieq "y" -or $Force -eq $true )
                    {
                        $configError = $false
                        foreach ( $element in $array )
                        {
                            # This is the adapter chosen
                            $value = $null
                            $value = $netadapterHashtable.get_item("$element")
                            
                            $chosenAdapter = $null
                            $chosenAdapter = get-netadapter -Name "$value" -ErrorAction stop
                            
                            # Analyze the dependency
                            $adaptersToConfigure = @()
                            $adaptersToConfigure = analyze-AdapterDependency -chosenAdapter $chosenAdapter
                            if ( $adaptersToConfigure -eq $false )
                            {
                                $message = "Error occured determining the adapters to configure based on '$chosenAdapter'."
                                LOG-Writer -Message "$message" -Level ERROR -LogOnly
                                throw("$message")
                            }
                            
                            if ( @( $adaptersToConfigure ).count -gt 1 )
                            {
                                $message = "WARNING: Additional NICs detected. The following NICs will be configured:"
                                LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
                                foreach ( $nicName in  $( $adaptersToConfigure.Name ) )
                                {
                                    $myNicObject = $null
                                    $myNicObject = Get-NetAdapter -Name "$nicName" -ErrorAction SilentlyContinue
                                    $message = "--> $nicName"
                                    LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
                                    $message = "    Details: $( $myNicObject.interfaceDescription ), $( $myNicObject.MacAddress ), $( $myNicObject.LinkSpeed )"
                                    LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
                                }
                                if ( $Force -eq $false )
                                {
                                    $4answer = $null
                                    $4answer = read-host -Prompt "Would you like to continue configuring the adapters (Y/N)?"
                                }
                                else
                                {
                                    $message = "Force configuration. Skipping user confirmation."
                                    LOG-Writer -Message "$message" -Level VERBO -CliUsesMessageOnly
                                }
                                if ( $4answer -ieq "y" -or $Force -eq $true )
                                {
                                    LOG-Writer -Message "Received user confirmation to continue configuration." -Level DEBUG -LogOnly
                                    $continue = $true
                                }
                                else
                                {
                                    $message = "Skipping configuration due to user abort."
                                    LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
                                    $continue = $false
                                }
                            }
                            else
                            {
                                LOG-Writer -Message "Adapter '$value' is a pNIC and does not have downstream dependencies." -Level DEBUG -LogOnly
                            }                       
                        
                            if ( $continue -eq $true )
                            {
                                foreach ( $object in $adaptersToConfigure )
                                {
                                    $result = $null
                                    $result = configure-NIC -dcsInstalled $dcsInstalled -adapterObject $object -restoreDefaults $restoreDefaults -includeGlobalSettings $includeGlobalSettings
                                    if ( $result -eq $false )
                                    {
                                        $configError = $true
                                        # break the inner loop
                                        break
                                    }
                                }
                            }

                            if ( $configError -eq $true )
                            {
                                # break the outer loop
                                break
                            }
                        }
                        
                        write-host " "
                        if ( $configError -eq $false )
                        {
                            $message = "No errors have been detected during configuration loop."
                            LOG-Writer -Message "$message" -Level SUCCE -CliUsesMessageOnly
                        }
                        else
                        {
                            $message = "Something went wrong through the configuration loop. Please check the output."
                            LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
                        }

                        $2answer = $null
                        $2answer = Read-Host "Would you like to end this script (Y/N)?"
                        $2answer = $2answer.trim()
                        if ( $2answer -ieq "y" )
                        {
                            LOG-Writer -Message "Received answer to end the script." -Level DEBUG -LogOnly
                            break
                        }
                    }
                    else
                    {
                        $message = "Skipping configuration due to user abort."
                        LOG-Writer -Message "$message" -Level WARNI -CliUsesMessageOnly
                    }
                }
            }
        }
    }
    elseif ( -not ( "$NetAdapters" -eq "" ) )
    {
        # THIS MODE IS KEPT FOR BACKWARD COMPATIBILITY
        LOG-Writer -Message "NetAdapters : $NetAdapters" -Level DEBUG -LogOnly
        LOG-Writer -Message "This mode of operation does not analyze potential dependencies. You need to make sure that all adapters passing iSCSI-Traffic are configured." -Level INFOR -CliUsesMessageOnly

        $adaptersToConfigure = $null
        $adaptersToConfigure = Get-NetAdapter -Name $NetAdapters -ErrorAction SilentlyContinue

        $result = $null
        $result = configure-NICs -dcsInstalled $dcsInstalled -adaptersToConfigure $adaptersToConfigure -restoreDefaults $restoreDefaults -includeGlobalSettings $includeGlobalSettings
    }
    elseif ( -not ( "$adapterIdentifier" -eq "" ) )
    {
        LOG-Writer -Message "adapterIdentifier : $adapterIdentifier" -Level DEBUG -LogOnly
        LOG-Writer -Message "This mode of operation does not analyze potential dependencies. You need to make sure that all adapters passing iSCSI-Traffic are configured." -Level INFOR -CliUsesMessageOnly
        if ( $restoreDefaults )
        {
            LOG-Writer -Message "Note: 'restoreDefaults' parameter provided. This sets adapter settings to default value." -Level WARNI -CliUsesMessageOnly
        }
        if ( $includeGlobalSettings )
        {
            LOG-Writer -Message "Note: 'includeGlobalSettings' parameter provided. This sets global settings to default value." -Level WARNI -CliUsesMessageOnly
        }
        LOG-Writer -Message "Trying to find adapter with exact name." -Level DEBUG -LogOnly

        # First we try to find an adapter with the exact name
        $adaptersToConfigure = $null
        $adaptersToConfigure = get-netadapter -name $adapterIdentifier -ErrorAction SilentlyContinue
        # We do a fallback on wildcard
        if ( -not $adaptersToConfigure )
        {
            LOG-Writer -Message "No exact name found. Trying to find adapter(s) through 'imatch' operator." -Level DEBUG -LogOnly
            $adaptersToConfigure = get-netadapter -ErrorAction SilentlyContinue | where { $_.name -imatch "$adapterIdentifier" }
        }

        $result = $null
        $result = configure-NICs -dcsInstalled $dcsInstalled -adaptersToConfigure $adaptersToConfigure -restoreDefaults $restoreDefaults -includeGlobalSettings $includeGlobalSettings
    }
    else
    {
        throw("Do not know what to do. Please use either parameters correctly or run on the interactive mode of this script.")
    }
}
else
{
    $message = "The detected version of Microsoft Windows is currently not supported. This script may only be run on Microsoft Windows 2012, 2012R2, 2016 and 2019."
    LOG-Writer -Message "$message" -Level ERROR -CliUsesMessageOnly
    Throw("$message")
}

### Disconnect from the DataCore server
if ( $dcsInstalled -eq $true )
{
    LOG-Writer -Message "Disconnecting from server." -Level DEBUG -LogOnly
    $result = $null 
    $result = dcsx-connection -server localhost -action cleanup
    if ( $result -eq $false )
    {
        LOG-Writer -Message "Failed disconnecting from server." -Level ERROR -CliUsesMessageOnly
    }
}

### Closing down
if ( $sessionIsInteractive -eq $true )
{
    write-host " " 
    write-host " " 
    write-host "==========================================================="
}
LOG-Writer -Message "Script ended." -Level INFOR -CliUsesMessageOnly
if ( $sessionIsInteractive -eq $true )
{
    write-host "==========================================================="
    write-host " " 
    write-host " " 
}
