.
function Get-DCOMSecurity{

    <#
        .SYNOPSIS

            Enumerate DCOM Security Settings
            Author: Matt Pichelmayer
          
        .DESCRIPTION
            
            This script is used to enumerate security settings based on WMI information from the Win32_DCOMApplication, 
            Win32_DCOMApplicationAccessAllowedSetting, and Win32_DCOMApplicationLaunchAllowedSetting for detecting 
            potential lateral movement avenues.  For more information on DCOM-based lateral movement concept, refer to the 
            following article: https://enigma0x3.net/2017/01/23/lateral-movement-via-dcom-round-2/

        .PARAMETER ComputerName

            If using this script locally, you can direct it to run against a remote workstation using the ComputerName 
            argument.  If omitted, the local workstation is assumed.

        .PARAMETER ListGroups

            List Available SIDs and their Groups

        .PARAMETER Username

            If using this script locally, you can direct it to run against a remote workstation using the ComputerName 
            argument.  If omitted, the local workstation is assumed.

        .PARAMETER SID

            If using this script locally, you can direct it to run against a remote workstation using the ComputerName 
            argument.  If omitted, the local workstation is assumed.
  
        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity
    		
            Enumerates DCOM security settings on the local computer
   
        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity -ComputerName <hostname>
    		
            Enumerates DCOM security settings on a remote computer
    #>    

    function Get-UserFromSID($SIDstr){

        $sid_obj = New-Object System.Security.Principal.SecurityIdentifier($SIDstr)
        return ($sid_obj.translate([System.Security.Principal.NTAccount])).Value

        }

    $dcom_apps = ([wmiclass]'win32_dcomapplication').GetInstances()
    $dcom_accesssettings = ([wmiclass]'Win32_DCOMApplicationAccessAllowedSetting').GetInstances()
    $dcom_launchsettings = ([wmiclass]'Win32_DCOMApplicationLaunchAllowedSetting').GetInstances()

    foreach($app in $dcom_apps){

        $access_table_entry = "Not Set"
        $launch_table_entry = "Not Set" 
        $dcom_appid = $app.appid
        $dcom_appname = $app.name

        #resolve launchaccess sids
        foreach($access in $dcom_accesssettings){

            if((($access.element).split("=")[1].replace("`"","")) -eq $dcom_appid){

                $access_sid = (($access.setting).split("=")[1]).replace("`"","")
                
                try   { $access_principal = Get-UserFromSID($access_sid) }
                catch { $access_principal = "Unknown" }

                $access_table_entry = "$access_sid ($access_principal)" 

                }
            }

        foreach($launch in $dcom_launchsettings){

            if((($launch.element).split("=")[1].replace("`"","")) -eq $dcom_appid){

                $launch_sid = (($launch.setting).split("=")[1]).replace("`"","")
                
                try   { $launch_principal = Get-UserFromSID($launch_sid) }
                catch { $launch_principal = "Unknown" } 

                $launch_table_entry = "$launch_sid ($launch_principal)" 

                }

            }

        $dcomsec = New-Object PSObject
        $dcomsec | Add-Member -Name "AppName" -MemberType NoteProperty -Value $dcom_appname
        $dcomsec | Add-Member -Name "AppID" -MemberType NoteProperty -Value $dcom_appid
        $dcomsec | Add-Member -Name "LaunchAllowedPrincipal" -MemberType NoteProperty -Value $access_table_entry
        $dcomsec | Add-Member -Name "AccessAllowedPrincipal" -MemberType NoteProperty -Value $launch_table_entry
        [array]$dcomsec
        
        }
    }
