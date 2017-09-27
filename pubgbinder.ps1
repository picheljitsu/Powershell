$msg = @'


***************************************************************************************
  ____  _   _ ____   ____                       
 |  _ \| | | | __ ) / ___|                      
 | |_) | | | |  _ \| |  _                       
 |  __/| |_| | |_) | |_| |                      
 |_| __ \___/|____/_\____|         _            
 | |/ /___ _   _| __ )(_)_ __   __| | ___ _ __  
 | ' // _ \ | | |  _ \| | '_ \ / _` |/ _ \ '__| 
 | . \  __/ |_| | |_) | | | | | (_| |  __/ |    
 |_|\_\___|\__, |____/|_|_| |_|\__,_|\___|_|    
           |___/  		
This script generates an .ahk file on the desktop to re-map your PUBG jump 		        
and crouch key to the Spacebar key for PUBG. If you have issues, killing 		        
the AutoHotKey (the green "H" icon in system tray) program will stop any 		        
scripts and restore your default keys.  Script is as-is and use at your own risk.               

I know what you're thinking: Why just the Space and Shift keys? Because AHK 		    
scripting isn't the most standardized language.  If there's interest, more can be made. 
I just don't have the time right now.  Sorrrry bruuu =(					

      Steam contact: http://steamcommunity.com/id/datvanquish  
                      
***************************************************************************************
			
'@

#Code when Shift = Jump and C = Crouch
$shift_code = @'
#IfWinActive ahk_exe TslGame.exe ; If active window is PUBG
LShift::                         ; When Left Shift is pressed
   send, +c                      ; Send Left Shift and Crouch (c key)
return
'@

#Code when Spacebar = Jump and C = Crouch
$space_code = @'
#IfWinActive ahk_exe TslGame.exe ; If active window is PUBG
Space::                          ; When Space is pressed
   send, Space & c               ; Send Spacebar and Crouch (c key)
return
'@

$status_message = ''
$completed = 0

$opt_msg=@'
[1] Spacebar is Jump & "c" is Crouch
[2] Shift is Jump & "c" is Crouch
Choose an option and press enter
'@

#Unzip function for Powershell version that don't have expand-archive
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip-File{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }


function Invoke-AhkDownload {

    sleep 1
    $uri = "https://autohotkey.com/download/2.0/AutoHotkey_v2.0-a075_x64.zip"
    $outdir = "$env:USERPROFILE\Downloads\"
    $outfile = "ahk.zip"
    $out_fullpath = $outdir+$outfile
    invoke-webrequest -uri $uri -OutFile $out_fullpath
    try { if($(test-path $out_fullpath)){
              $status_message = "File successfully downloaded..."
              }
          return $status_message }
    catch { Write-Output "Couldn't Download File =(" 
          return $complete = 1 }

    }

function Expand-AhkDownload {
    $status_message = "File successfully extracted to Desktop"
    if(-not $(test-path "$env:USERPROFILE\Desktop\AutoHotKey.exe")){

        if($PSVersionTable.PSVersion.Major -eq 5){
            write-host "Powershell Version 5 detected"
            Expand-Archive $out_fullpath -DestinationPath "$env:USERPROFILE\Desktop"
            }
        else{
            write-host "Powershell Version below 5" 
            Unzip-File $out_fullpath "$env:USERPROFILE\Desktop\" 
            }
            test-path "$env:USERPROFILE\Desktop\AutoHotKey.exe"
        }
    else{ $complete = 1} 
         return $complete
    }


#Start the install and extraction
while($completed -eq 0){
    clear-host
    write-output $msg
    write-host $status_message
    $confirm_download = read-host "Download and extract AutoHotKey? (y/n)"
    if($confirm_download -eq 'n'){
        sleep 3
        $competed = 1 
        break 
        }         
    if($confirm_download -eq 'y'){
        write-host "Downloading AutoHotkey Zip File..." -f Green
        $status_message = Invoke-AhkDownload | Out-Null
        if($status_message -ne 1){ 
            write-host "File Successfully Downloaded..." -f Green
        if($status_message -eq 1){
            $completed = 1
            break 
            }
        sleep 3

        Write-Host "Extracting File to Desktop..." -f Green
        $status_message = Expand-AhkDownload | Out-Null
        if($status_message -ne 1){
        write-host "File Successfully Extracted..." -f Green
            }
        if($status_message -eq 1){
            $completed = 1
            break 
            }        
        sleep 3
        }
    }
    #Select the Keys to Re-map
    while($true){

        Write-host $status_message
        $get_key = read-host $opt_msg 
    
        if($get_key -eq 1){
            Write-Output "Binding script to 'Left Shift' key"
            $script = $shift_code
            break
            }
        if($get_key -eq 2){
            Write-Output "Binding script to 'Spacebar' key"
            $script = $space_code
            break
            }
        else{ $status_message = "Invalid option. Choose 1 or 2." }
        }

    #AutoHotKey.ahk was detected so confirm overwrite
    if(test-path "$env:USERPROFILE\Desktop\AutoTest.ahk"){
        
         $overwrite = ''
         $getanswer = ''

         while($overwrite -ne "y" -or $overwrite -ne "n"){
            clear-host
            $status_message = "Invalid option. Choose y or n" 
            write-output $msg

            $overwrite = read-host "AutoHotKey.ahk already exists on the Desktop! Do you want to overwrite it (y/n)?"
    
            if($overwrite -eq "y"){
               rm $env:USERPROFILE\Desktop\AutoTest.ahk 
               $script > $env:USERPROFILE\Desktop\AutoTest.ahk 
               read-host "Done! Press any key to continue" 
               $completed = 1
               break
               }
            if($overwrite -eq "n"){ 
               read-host "Abortion encountered. Press any key to close"
               exit
               }
            write-host $status_message -f Red 
            }
        }
    else { $script > $env:USERPROFILE\Desktop\AutoTest.ahk 
           write-host "Done! Remember, you'll need to manually start the
           AutoHotKey program on your desktop each time you restart your computer.
           You should see the green 'H' icon in your system tray if it's running."
          }
           $launch = read-host = "Start the AutoHotKey Process? (y/n)"
           if($launch -eq 'y'){
                Start-Process "$env:USERPROFILE\Desktop\AutoHotKey.exe"
                }

    }
