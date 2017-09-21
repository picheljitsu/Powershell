
function Parse-AuthLogs{

    <#
        .SYNOPSIS

            Parses Security Authenticaiton Event Logs
            Author: Matt Pichelmayer
            License: BSD 3-Clause
            Required Dependencies: None
            Optional Dependencies: None   
          
        .DESCRIPTION
            
            Provides a quick summary of local and remote authentication. Parses Interactive, Network and Remote logons from the 
            Get-EventLog CmdLet for a quick summary of who logged in to a workstation.

        .PARAMETER ComputerName

            If using this script locally, you can direct it to run against a remote workstation using the ComputerName argument.  If omitted,
            the local workstation is assumed.

        .PARAMETER StartTime 

            What date/time to start the log parsing.  You can use the AddDays and AddHours method from the Get-Date cmdlets.  Can only be used
            with the EndTime parameter.  See examples.
            
        .PARAMETER EndTime 

            Optional parameter.  If not set, the current date/time is used.  
        
        .PARAMETER HoursBack 
            
            Specify a positive integer to indicate how far back, in hours, the search should begin.  Can only be used
            with the (optional) DaysBack parameter. 
        
        .PARAMETER DaysBack         

            Specify a positive integer to indicate how far back, in days, the search should begin.  Can only be used
            with the (optional) HoursBack parameter. 

        .PARAMETER ResolveIPs
            
            Optional argument to resolve IP addresses to host names for source addresses.  Source Addresses are where the connections 
            originated from.    
        
        .EXAMPLE
    
            PS C:\> Parse-AuthLogs -StartTime "9/19/2017" -EndTime "9/20/2017"
    		
            Parses all logs for 19th day of September

        .EXAMPLE

            PS C:\> Parse-AuthLogs -computername L6034553 "9/10/2017" "9/20/2017"

            Parses all logs on the host L6034553 from September 10th to September 20th

        .EXAMPLE
    
            PS C:\> Parse-AuthLogs -StartTime (Get-Date).AddDays(-3) -EndTime (Get-Date).AddHours(-20)
    		
            Parses all logs starting 3 days back, up to 20 hours before the current time.

        .EXAMPLE
    
            PS C:\> Parse-Authlogs -DaysBack 2
    		
            Parses logs 2 days (48 hours) back from the current time

        .EXAMPLE
    
            PS C:\> Parse-Authlogs -HoursBack 2
    		
            Parses logs 2 hours back from the current time

        .EXAMPLE
    
            PS C:\> Parse-Authlogs -DaysBack 2 -HoursBack 13
    		
            Parses logs 2 days and 13 hours back
    		
    #>
    [CmdletBinding(DefaultParameterSetName='StartEnd')]
    param([parameter( Mandatory=$false)]
                      [string]$ComputerName='.',
          [parameter( ParameterSetName='StartEnd',
                      Mandatory=$true,
                      position=0)]
                      [datetime]$StartTime,
          [parameter( ParameterSetName='StartEnd',
                      Mandatory=$false,
                      position=1)]
                      [datetime]$EndTime=$(Get-date),
          [parameter( ParameterSetName='TimeBack',
                      Mandatory=$false,
                      position=0)]
                      [int]$HoursBack,
          [parameter( ParameterSetName='TimeBack',
                      Mandatory=$false,
                      position=1)]
                      [int]$DaysBack,
          [parameter( Mandatory=$false,
                      ValueFromPipeline=$false)]
                      [switch]$ResolveIPs
                      
                      )
            
    $array_object = @()

    #The following hash tables are used to resolve the values output from ReplacementsStrings
    #method for each log object returned from the Get-EventLog cmdlet.
    #String for success/fail logons are different between 4624 and 4625
    $logon_map = @{ "success_logon" = 8; "fail_logon" = 10 }
    $account = @{ "account" = 5; "logoff_account" = 1 }
    $authentication = @{"success_auth" = 10; "fail_auth" = 12 }
    $ip_field = @{"ip_success" = 18; "ip_fail" = 19 }
    #User friends Logon Types
    $logon_dict = @{ "2" = "2: Interactive"; "3" = "3: Network"; "10" = "10: RDP" }
    if($StartTime){
        $start = $StartTime
        }
    if($HoursBack){
        $start = (get-date).AddHours($HoursBack * -1)
        Write-Output "Starttime is: $start"
        Write-Output "Endtime is: $endtime"
        }
    if($DaysBack){
        $start = (get-date).AddDays($DaysBack * -1)
        }
    if($HoursBack -AND $DaysBack){
        $start = ((get-date).AddDays($DaysBack * -1)).AddHours($HoursBack * -1)
        }

    ForEach($event in Get-EventLog -LogName Security -ComputerName $ComputerName | Where-Object { $_.TimeGenerated -gt $start -and $_.TimeGenerated -lt $endtime }){

            if( ($event.eventId -eq 4624 `
                -AND
                $event.ReplacementStrings[5] -notmatch '.*?\$' ) `
                -AND
                ( $event.ReplacementStrings[8] -eq 2 `
                -OR    `
                $event.ReplacementStrings[8] -eq 3 `
                -OR    `
                $event.ReplacementStrings[8] -eq 10)) {

                       $custom_object = New-Object PSObject            
                       $custom_object | Add-Member -Name "Time" -MemberType NoteProperty -Value $event.TimeGenerated.ToString('g') 
                       $custom_object | Add-Member -Name "Event ID" -MemberType NoteProperty -Value $event.eventID
                       $custom_object | Add-Member -Name "Result" -MemberType NoteProperty -Value "Success"
                       $custom_object | Add-Member -Name "Logon Type" -MemberType NoteProperty -Value $logon_dict.item($event.ReplacementStrings[8])          
                       $custom_object | Add-Member -Name "Authentication" -MemberType NoteProperty -Value $event.ReplacementStrings[10]
                       $custom_object | Add-Member -Name "Account" -MemberType NoteProperty -Value $event.ReplacementStrings[5]
                       if($event.ReplacementStrings[18].Length -gt 4){
                            #Get the hostname 
                            if($ResolveIPs){
                                try{$source_address = [System.Net.Dns]::GetHostbyAddress($event.ReplacementStrings[18]).HostName.Split('.')[0]}
                                catch{$source_address = $event.ReplacementStrings[18] + " (Failed Lookup)"}
                                }
                       else{$source_address = $event.ReplacementStrings[18]}
                                                                     
                       $custom_object | Add-Member -Name "Source Address" -MemberType NoteProperty -Value $source_address
                       $array_object += $custom_object
          
                      }
                }
             if( $event.eventId -eq 4625 `
                 -AND
                 $event.ReplacementStrings[10] -eq 2 `
                 -OR    `
                 $event.ReplacementStrings[10] -eq 3 `
                 -OR    `
                 $event.ReplacementStrings[10] -eq 10){

                        $custom_object = New-Object PSObject            
                        $custom_object | Add-Member -Name "Time" -MemberType NoteProperty -Value $event.TimeGenerated.ToString('g') 
                        $custom_object | Add-Member -Name "Event ID" -MemberType NoteProperty -Value $event.eventID
                        $custom_object | Add-Member -Name "Result" -MemberType NoteProperty -Value "Failed"
                        $custom_object | Add-Member -Name "Logon Type" -MemberType NoteProperty -Value $logon_dict.item($event.ReplacementStrings[10])          
                        $custom_object | Add-Member -Name "Authentication" -MemberType NoteProperty -Value $event.ReplacementStrings[12]
                        $custom_object | Add-Member -Name "Account" -MemberType NoteProperty -Value $event.ReplacementStrings[5]
                       if($event.ReplacementStrings[19].Length -gt 4){
                            #Get the hostname 
                            if($ResolveIPs){
                                $source_address = [System.Net.Dns]::GetHostbyAddress($event.ReplacementStrings[19]).HostName.Split('.')[0]
                                }
                            else{$source_address = $event.ReplacementStrings[19]}
                            }
                       else{$source_address = "Local"}
                        $custom_object | Add-Member -Name "Source Address" -MemberType NoteProperty -Value $source_address
                        $array_object += $custom_object
         
                       }

             if( $event.eventId -eq 4647 ){
           
                        $custom_object = New-Object PSObject            
                        $custom_object | Add-Member -Name "Time" -MemberType NoteProperty -Value $event.TimeGenerated.ToString('g') 
                        $custom_object | Add-Member -Name "Event ID" -MemberType NoteProperty -Value $event.eventID
                        $custom_object | Add-Member -Name "Result" -MemberType NoteProperty -Value "LogOff"
                        $custom_object | Add-Member -Name "Logon Type" -MemberType NoteProperty -Value "N/A"          
                        $custom_object | Add-Member -Name "Authentication" -MemberType NoteProperty -Value "N/A"
                        $custom_object | Add-Member -Name "Account" -MemberType NoteProperty -Value $event.ReplacementStrings[1]
                        $custom_object | Add-Member -Name "Source Address" -MemberType NoteProperty -Value "N/A"
                        $array_object += $custom_object
           
                       }

                }
                $array_object | Format-Table -AutoSize

     }
    

    
