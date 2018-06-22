function Trace-ProcessCreation { 

    <#

    .SYNOPSIS
    
    Monitors Process Creation and Grabs WMI Information on the process

    Version: 1.0
    Author : Matt Pichelmayer
    License: BSD 3-Clause
        
    .DESCRIPTION

    .EXAMPLE
    
    PS C:\> Trace-ProcessCreation

    #>

    [CmdLetBinding()]            
    param([parameter()]
          [int]$Timeout=5,
          [parameter()]
          [string]$TraceName="StartProcess",
          [parameter()]
          [switch]$UnRegister,
          [parameter()]
          [switch]$NoBlock
          )
    
    if($UnRegister){
        
        if(Get-EventSubscriber -SourceIdentifier $TraceName){

            Get-EventSubscriber -SourceIdentifier $TraceName | Unregister-Event

            $msg = "[+] Removed event subscription"

            }

        elseif(-not (Get-EventSubscriber)){ $msg = "[-] There aren't any event subscriptions running" }

        else { $msg = "[-] No EventSubcription with the SourceIdentifier $TraceName" }

        write-host $msg

        }

    else{

        $Timeout = $Timeout * 60

        $Query =  "Select * from win32_ProcessStartTrace"               
        $ActionBlock = {            
            
            $trappedProc = $event.SourceEventArgs.NewEvent           

            $wmiProcInfo = @{}
            $wmiProcCollector = { $wmiProcInfo.add("ParentProcessID", $_.ParentProcessID )
                                  $wmiProcInfo.add("CommandLine", $_.commandline )
                                  $wmiProcInfo.add("CreationTime", $_.ConvertToDateTime($_.CreationDate))}

            Get-WMIObject win32_process | Where-Object { $_.processid -eq $trappedProc.processid } | ForEach $wmiProcCollector
            Get-WMIObject win32_process | Where-Object { $_.processid -eq $wmiProcInfo['ParentProcessID'] } | Foreach { $wmiProcInfo.Add("ParentProcessName", $_.Name) }

            $procInfo = @{ "ProcessName" = $trappedProc.ProcessName
                           "ProcessID" = $trappedProc.ProcessID
                           "CreationTime" = $wmiProcInfo['CreationTime']
                           "CommandLine" =   $wmiProcInfo['CommandLine']
                           "ParentProcessName" = $wmiProcInfo['ParentProcessName']
                           "ParentProcessID" = $wmiProcInfo['ParentProcessID']
                         }

            $procInfo | Out-Host | Format-List

            }            
        }

    Register-CimIndicationEvent -Query $Query -SourceIdentifier $TraceName -Action $ActionBlock | Out-Null

    if(-not $NoBlock){
        #Block shell. Prevents leaving the subscription running.
        while(1){ sleep $Timeout
                  break }

        Unregister-Event -SourceIdentifier $TraceName

        }
    else { Write-Warning "[!] Completed Event Subscription. Leaving a subscription running may cause system stability issues due to memory consumption. To remove, execute the following command:"
           Write-Host "Unregister-Event -SourceIdentifier $Tracename" }

      
    }

  
