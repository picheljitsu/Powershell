#hit the windows key, type powershell
#right-click powershell_ISE and select "Run-As administrator"
#Run Set-ExecutionPolicy Unrestricted
#past the below in and run

$signature=@' 
      [DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
      public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@ 

$mc = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru 

$a = $True
while(1){

    $d = ([System.Windows.Forms.Cursor]::Position).y * .005

    switch([System.Windows.Forms.UserControl]::MouseButtons) {
    
        "Left"  {  echo "Left click"
                   $mc::mouse_event(0x01, 0, $d , 0, 0)
                   sleep -Milliseconds .8
                   #$mc::(0x00000004, 0, 0, 0, 0)
                    }
        "None"  {
                  #$mc::mouse_event(0x00000010, 0, 0, 0, 0); 
                    }

        }

    
    }
