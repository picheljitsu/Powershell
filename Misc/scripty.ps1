function Move-Mouse {

    [CmdletBinding()]
    param([parameter]
          [int]$Move,
          [parameter]
          [int]$Delay)
    
    #Allows for running in PS console
    Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Windows.Forms, System.Drawing
	$State = [hashtable]::Synchronized(@{ "Started" = $True })
    $MenuHeader = "************** Select Profile **************"
          
    $MouseClickBlock = {       
                    param($Move, $Delay)

                    #WinAPI to find active Window
                    $WinAPI1 += '[DllImport("user32.dll")]'
                    $WinAPI1 += 'public static extern IntPtr GetForegroundWindow();'

                    #WinAPI mouse event
                    $WinAPI2 = '[DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]'
                    $WinAPI2 += 'public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);'
                    try {
                         Add-Type -MemberDefinition $WinAPI2 -Name "MouseEvent" -Namespace "WinAPI"
                         Add-Type -MemberDefinition $WinAPI1 -Name "Window" -Namespace "WinAPI"
                        }
                    catch [System.Exception] { }

                    $ForeGroundProc = [WinAPI.Window]::GetForeGroundWindow()


        
                    $d = ([System.Windows.Forms.Cursor]::Position).y * $Move
                    
                    while(1){
                            switch([System.Windows.Forms.UserControl]::MouseButtons) {
                            
                                "Left"  {  [WinAPI.MouseEvent]::mouse_event(0x01, 0, $d , 0, 0)
                                           sleep -Milliseconds $Delay 
                                           break }
                                }
                                        
                        } #End while
  
                    } #End Scriptblock
 
    $msg = ''
    $menuOpts = @{ "1" = @{ "Move" = .005 ; "Delay" = 10 }
							"2" = @{ "Move" = .007  ; "Delay" = 10 } 
							"3" = @{ "Move" = .009 ; "Delay" = 10 }
							"4" = @{ "Move" = .011 ; "Delay" = 10 } 
							}

    $Choices = [array]$menuOpts.Keys | sort 
    $Choices += "Quit"

    $runnin = $True
    while($runnin){ 
	
        sleep .2
        clear-host
		
        write-host $($MenuHeader) -ForegroundColor Green

        for($i = 0; $i -lt $Choices.count; $i++){

           $CurrentChoice = $($choices[$i])
           
           $State = " "        
           if($SelectedOpt -eq $CurrentChoice){ $state = "X" }
           $Toggled = "[$State]"
           write-host "$($i+1)) $Toggled $CurrentChoice" -ForegroundColor Green
           sleep .2
        
           }       

        write-host $msg -f red
        $GunProfile = read-host "Choose yo option"

        $SelectedOpt = $Choices[$Gunprofile - 1]

        if($Choices -notcontains $SelectedOpt){ $msg = "Dumbass. That ain't on the menu" }

        if($SelectedOpt -eq "Quit"){ 

            try  {[void]$MouseThread.stop()}
            catch{ }                   
            $Msg = "Script Inactive" 
            
            }

        else{ 
              try{ $MouseThread.Stop(); $MouseThread.dispose() }
              catch { } 
			  $MouClickParams = $menuOpts[$choices[$GunProfile-1]]
			  sleep -mil 3  
			  $MouseThreadEnv = [RunspaceFactory]::CreateRunspace()
			  $MouseThreadEnv.Open()
			  $MouseThreadEnv.SessionStateProxy.SetVariable('State',$State)
			  $MouseThread = [PowerShell]::Create()
			  $MouseThread.runspace = $MouseThreadEnv
              [void]$MouseThread.AddScript($MouseClickBlock)

              $Msg = "Running $SelectedOpt Profile..." 
              
              [void]$MouseThread.AddParameters($MouClickParams)
              [void]$MouseThread.BeginInvoke() 
              
             }

        }

    }   

Move-Mouse  
