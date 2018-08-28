function Move-Mouse {

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
    $MenuHeader = "************** Select Profile **************"
          
    $MouseClickBlock = {       
                    param($Move, $Delay)

                    $signature='[DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]'
                    $signature += 'public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);'
                        
                    $mc = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru 
                    $d = ([System.Windows.Forms.Cursor]::Position).y * $Move
                    
                    while(1){

                        switch([System.Windows.Forms.UserControl]::MouseButtons) {
                            
                            "Left"  {  $mc::mouse_event(0x01, 0, $d , 0, 0)
                                       sleep -Milliseconds $Delay 
                                       break }
                                        
                            } #End switch 1

                        } #End while
  
                    } #End Scriptblock
 
    $msg = ''
    $menuOpts = @{ "AK" = @{ "Move" = .008 ; "Delay" = 5 }
                   "AR" = @{ "Move" = .007 ; "Delay" = 5 } }

    $Choices = [array]$menuOpts.Keys
    $Choices += "Quit"
    

    #$start = Read-host "Press enter to start or type QUit to quit, beeitch"
    [void]$MouseThread.AddScript($MouseClickBlock)
    #$MouseThread.BeginInvoke() #| Out-Null
    sleep 2

    $runnin = $True
    while($runnin){ 


        clear-host
        write-host $MenuHeader

        for($i = 0; $i -lt $Choices.count; $i++){

           write-host "$($i+1)) $($choices[$i])"
        
           }       

        write-host $msg -f red
        $GunProfile = read-host "Choose yo gun type"
        try {[void]$MouseThread.stop()}
        catch {}       
        $Gun = $Choices[$Gunprofile - 1]

        if($Choices -notcontains $Gun){
            
             $msg = "Dumbass. That ain't on the menu"

             }

        else{ $MouClickParams = $menuOpts[$choices[$GunProfile-1]]
              $Msg = "Running $Gun Profile..." }

        $MouClickParams = $menuOpts[$choices[$GunProfile-1]]
        [void]$MouseThread.AddParameters($MouClickParams)
        #$start = read-host "Press any key to start" 
        [void]$MouseThread.BeginInvoke()
        
        }

    }            
