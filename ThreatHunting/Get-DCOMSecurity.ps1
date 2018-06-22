function Get-DCOMSecurity{

    <#
        .SYNOPSIS

            Enumerates and Maps DCOM Access and Launch ACL Settings
          
        .DESCRIPTION
            
            This script is used to enumerate security settings based on WMI information from the Win32_DCOMApplication, 
            Win32_DCOMApplicationAccessAllowedSetting, and Win32_DCOMApplicationLaunchAllowedSetting for detecting 
            potential avenues for lateral movement or persistence.  For more information on DCOM-based lateral movement concept, 
	    refer to the following article: https://enigma0x3.net/2017/01/23/lateral-movement-via-dcom-round-2/

        .PARAMETER ComputerName

            If using this script locally, you can direct it to run against a remote workstation using the ComputerName 
            argument.  If omitted, the local workstation is assumed.

        .PARAMETER ListSIDs

            Don't enumerate any settings, just list default SIDs and their groups.  For reference only.

        .PARAMETER ResolveSID

            Switch to enable SID resolution. The hashtable is used to resolve default SIDs, if a name isn't returned, a
	    query is performed via Active Directory.
  
        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity
    		
            Enumerates DCOM security settings on the local computer
   
        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity -ComputerName <hostname>
    		
            Enumerates DCOM security settings on a remote computer

        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity -ComputerName <hostname> -ListSIDs
    		
            Prints out a list of default SIDs and doesn't enumerate any security settings.

        .EXAMPLE
    
            PS C:\> Get-DCOMSecurity -ResolveSID -LaunchSettings | ? {$_.appname -like "*PLA*"}
    		
            Prints out all applications with *PLA* in the appname title with their LaunchSetting permissions
            and resolves the SIDs in the permissions.
	    
	.NOTES
	
            Enumerate DCOM Security Settings
            Author: Matt Pichelmayer
	    Version: 1.0
            License: BSD 3-Clause
    #>

    [CmdletBinding(DefaultParametersetName='Default')]
    param([parameter(Mandatory=$false,ParameterSetName='Default')]
          [string]$ComputerName=$env:COMPUTERNAME,
          [parameter(Mandatory=$false,ParameterSetName='ListGroups')]
          [switch]$ListSIDs,
          [parameter(Mandatory=$false,ParameterSetName='Default')]
          [switch]$AccessSettings,
          [parameter(Mandatory=$false,ParameterSetName='Default')]
          [switch]$LaunchSettings,
          [parameter(Mandatory=$false,ParameterSetName='Default')]
          [switch]$ResolveSID
          )

    #Known SIDs https://support.microsoft.com/en-us/help/243330/well-known-security-identifiers-in-windows-operating-systems
   
    $sid_table = @{

	    "S-1-0" = "Null Authority";
	    "S-1-0-0" = "Nobody";
	    "S-1-1" = "World Authority";
	    "S-1-1-0" = "Everyone";
	    "S-1-2" = "Local Authority";
	    "S-1-2-0" = "Local";
	    "S-1-2-1" = "Console Logon";
	    "S-1-3" = "Creator Authority";
	    "S-1-3-0" = "Creator Owner";
	    "S-1-3-1" = "Creator Group";
	    "S-1-3-2" = "Creator Owner Server";
	    "S-1-3-3" = "Creator Group Server";
	    "S-1-3-4 Name: Owner Rights" = "SID: S-1-3-4 Owner Rights";
	    "S-1-5-80-0" = "All Services";
	    "S-1-4" = "Non-unique Authority";
	    "S-1-5" = "NT Authority";
	    "S-1-5-1" = "Dialup";
	    "S-1-5-2" = "Network";
	    "S-1-5-3" = "Batch";
	    "S-1-5-4" = "Interactive";
	    "S-1-5-5-X-Y" = "Logon Session";
	    "S-1-5-6" = "Service";
	    "S-1-5-7" = "Anonymous";
	    "S-1-5-8" = "Proxy";
	    "S-1-5-9" = "Enterprise Domain Controllers";
	    "S-1-5-10" = "Principal Self";
	    "S-1-5-11" = "Authenticated Users";
	    "S-1-5-12" = "Restricted Code";
	    "S-1-5-13" = "Terminal Server Users";
	    "S-1-5-14" = "Remote Interactive Logon";
	    "S-1-5-15" = "This Organization";
	    "S-1-5-17" = "This Organization";
	    "S-1-5-18" = "Local System";
	    "S-1-5-19" = "NT Authority";
	    "S-1-5-20" = "NT Authority";
	    "S-1-5-21domain-500" = "Administrator";
	    "S-1-5-21domain-501" = "Guest";
	    "S-1-5-21domain-502" = "KRBTGT";
	    "S-1-5-21domain-512" = "Domain Admins";
	    "S-1-5-21domain-513" = "Domain Users";
	    "S-1-5-21domain-514" = "Domain Guests";
	    "S-1-5-21domain-515" = "Domain Computers";
	    "S-1-5-21domain-516" = "Domain Controllers";
	    "S-1-5-21domain-517" = "Cert Publishers";
	    "S-1-5-21root domain-518" = "Schema Admins";
	    "S-1-5-21root domain-519" = "Enterprise Admins";
	    "S-1-5-21domain-520" = "Group Policy Creator Owners";
	    "S-1-5-21domain-526" = "Key Admins";
	    "S-1-5-21domain-527" = "Enterprise Key Admins";
	    "S-1-5-21domain-553" = "RAS and IAS Servers";
	    "S-1-5-32-544" = "Administrators";
	    "S-1-5-32-545" = "Users";
	    "S-1-5-32-546" = "Guests";
	    "S-1-5-32-547" = "Power Users";
	    "S-1-5-32-548" = "Account Operators";
	    "S-1-5-32-549" = "Server Operators";
	    "S-1-5-32-550" = "Print Operators";
	    "S-1-5-32-551" = "Backup Operators";
	    "S-1-5-32-552" = "Replicators";
	    "S-1-5-64-10" = "NTLM Authentication";
	    "S-1-5-64-14" = "SChannel Authentication";
	    "S-1-5-64-21" = "Digest Authentication";
	    "S-1-5-80" = "NT Service";
	    "S-1-5-83-0" = "NT VIRTUAL MACHINE\Virtual Machines";
	    "S-1-16-0" = "Untrusted Mandatory Level";
	    "S-1-16-4096" = "Low Mandatory Level";
	    "S-1-16-8192" = "Medium Mandatory Level";
	    "S-1-16-8448" = "Medium Plus Mandatory Level";
	    "S-1-16-12288" = "High Mandatory Level";
	    "S-1-16-16384" = "System Mandatory Level";
	    "S-1-16-20480" = "Protected Process Mandatory Level";
	    "S-1-16-28672" = "Secure Process Mandatory Level";
	    "S-1-5-32-554" = "BUILTIN\Pre-Windows 2000 Compatible Access";
	    "S-1-5-32-555" = "BUILTIN\Remote Desktop Users";
	    "S-1-5-32-556" = "BUILTIN\Network Configuration Operators";
	    "S-1-5-32-557" = "BUILTIN\Incoming Forest Trust Builders";
	    "S-1-5-32-558" = "BUILTIN\Performance Monitor Users";
	    "S-1-5-32-559" = "BUILTIN\Performance Log Users";
	    "S-1-5-32-560" = "BUILTIN\Windows Authorization Access Group";
	    "S-1-5-32-561" = "BUILTIN\Terminal Server License Servers";
	    "S-1-5-32-562" = "BUILTIN\Distributed COM Users";
	    "S-1-5- 21domain -498" = "Enterprise Read-only Domain Controllers";
	    "S-1-5- 21domain -521" = "Read-only Domain Controllers";
	    "S-1-5-32-569" = "BUILTIN\Cryptographic Operators";
	    "S-1-5-21 domain -571" = "Allowed RODC Password Replication Group";
	    "S-1-5- 21 domain -572" = "Denied RODC Password Replication Group";
	    "S-1-5-32-573" = "BUILTIN\Event Log Readers";
	    "S-1-5-32-574" = "BUILTIN\Certificate Service DCOM Access";
	    "S-1-5-21-domain-522" = "Cloneable Domain Controllers";
	    "S-1-5-32-575" = "BUILTIN\RDS Remote Access Servers";
	    "S-1-5-32-576" = "BUILTIN\RDS Endpoint Servers";
	    "S-1-5-32-577" = "BUILTIN\RDS Management Servers";
	    "S-1-5-32-578" = "BUILTIN\Hyper-V Administrators";
	    "S-1-5-32-579" = "BUILTIN\Access Control Assistance Operators";
	    "S-1-5-32-580" = "BUILTIN\Remote Management Users"

    }

    if($ListSIDs){ Write-Output $sid_table }

    else {

        function Get-UserFromSID($SIDstr){
            if(-not $sid_table[$SIDstr]){

                $sid_obj = New-Object System.Security.Principal.SecurityIdentifier($SIDstr)
                return ($sid_obj.translate([System.Security.Principal.NTAccount])).Value
                
                }
            else { return $sid_table[$SIDstr] }

            }

        $dcom_apps = ([wmiclass]"\\$ComputerName\ROOT\CIMV2:win32_dcomapplication").GetInstances()
        $dcom_accesssettings =  ([wmiclass]"\\$ComputerName\ROOT\CIMV2:Win32_DCOMApplicationAccessAllowedSetting").GetInstances()
        $dcom_launchsettings = ([wmiclass]"\\$ComputerName\ROOT\CIMV2:Win32_DCOMApplicationLaunchAllowedSetting").GetInstances()

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

                    if($ResolveSID){

                        $access_table_entry = "$access_sid ($access_principal)" 

                        }
			
                    else{ $access_table_entry = $access_sid }

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

            if($LaunchSettings){

                $dcomsec | Add-Member -Name "LaunchAllowedPrincipal" -MemberType NoteProperty -Value $access_table_entry

                }

            if($AccessSettings){

                $dcomsec | Add-Member -Name "AccessAllowedPrincipal" -MemberType NoteProperty -Value $launch_table_entry

                }

            [array]$dcomsec
            
            }

        }

    }
