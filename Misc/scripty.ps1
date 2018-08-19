function Invoke-Recoil {
    [CmdletBinding()]
    param([parameter]
          [int]$Move,
          [parameter]
          [int]$Delay)

    $State = [hashtable]::Synchronized(@{ "Started" = $True })
    $MouseThreadEnv = [RunspaceFactory]::CreateRunspace()
    $MouseThreadEnv.Open()
    $MouseThreadEnv.SessionStateProxy.SetVariable('State',$State)
    $MouseThread = [PowerShell]::Create()
    $MouseThread.runspace = $MouseThreadEnv
    
    #$Move = .007
    #$Delay = .8
    #$MouClickParams = @{ "Move"  = $Move
    #                     "Delay" = $Delay }
    #
    $MouseClickBlock = {
    
                    
                    $signature='[DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]'
                    $signature += 'public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);'
                        
                    $mc = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru 
                    $d = ([System.Windows.Forms.Cursor]::Position).y * .003
                    
                    while(1){
                    
                        switch([System.Windows.Forms.UserControl]::MouseButtons) {
                        
                            "Left"  {  $mc::mouse_event(0x01, 0, $d , 0, 0)
                                       sleep -Milliseconds 2 }
                    
                            }
                                      
                        }
    
                    }
    
    #$msg = ''
    #$menuOpts = @{ "AK" = @{ "Move" = ".008" ; "Delay" = $Delay = ".8" }
    #               "AR" = @{ "Move" = ".007"; "Delay" = $Delay = ".8" } }
    #$Choices = [array]$menuOpts.Keys
    #write-host $Choices[0]
    #$Choices += "Quit"
    #
    #$Optscount = $menuOpts.Count - 1
    #write-host $Optscount

    Clear-Host
    $start = Read-host "Press enter to start or type QUit to quit, beeitch"
    [void]$MouseThread.AddScript($MouseClickBlock)
    $MouseThread.BeginInvoke() #| Out-Null
    sleep 2

    $runnin = $True
    while($runnin){ 
        $msg = ''
        write-host $msg
        $stop = read-host "Press any key to stop"
        $MouseThread.stop()        
        $start = read-host "Press any key to start" 
        $MouseThread.start()
        }

    }              
