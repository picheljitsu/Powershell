function Get-RecentFiles{
<#
    .SYNOPSIS

		Lists files in a user's Recent directory sorted by lastwritetime property.
        
    .DESCRIPTION

        The files returned in the specified user's Recent directory are .lnk files.  Analyzing the 
        contents of the files will show what documents were accessed as Windows mantains a history 
        of recently used files by generating a link and placing them in the 
        %userprofile%\AppData\Roaming\Microsoft\Windows\Recent

    .EXAMPLE

        PS C:\> Get-RecentFiles -username lolbox
		
        Performs a listing of the user's recents directory
	
    .EXAMPLE

        PS C:\> Get-RecentFiles -username lolbox -Parse
		
        Performs a listing of the user's recents directory and parses each link
		
#>

        [cmdletbinding()]
        param(
            [parameter(Mandatory=$true,ValueFromPipeline=$true)] 
            [validateScript({test-path "C:\Users\$_"})]
            [string]$UserName,
            [switch]$Parse
            )

        $recent = "C:\Users\$username\AppData\Roaming\Microsoft\Windows\Recent"

        if(Test-path $recent){

            Try{Set-Location $recent
                if($parse){
                    Get-ChildItem $recent -Filter *.lnk | sort lastwritetime | Parse-LnkFile
                    }

                else{Get-ChildItem $recent}
                }

            Catch{Write-host $Error[0].Exception}
            }

        else{write-host "$username doesn't exist. Check C:\Users"}

        }

function Parse-LnkFile{
<#
    .SYNOPSIS

		Parses .lnk file to the true path on disk
        
    .DESCRIPTION

        Returns a hashtable of the .lnk File name, the associated file on disk and tests whether the file still exists.

    .EXAMPLE

        PS C:\> Parse-LnkFile test.txt.lnk
		
        Returns the File on disk which the lnk file redirects to.
		
#>
        [CmdletBinding()]
        param (
                [parameter(Mandatory=$true,ValueFromPipeline=$true)] 
                [string]$file
                )
        BEGIN{ $root_path = "$((get-location).Path)"
               $out_array = @() 
               }
        PROCESS{

            try{
                
                #Read file in as a raw ASCII string
                $file_contents = [IO.File]::ReadAllText($root_path+"\"+$file)

                #Split contents into an array.  Spaces are actually null characters and not ASCII space characters
                $content_array = $file_contents -split "[\x00]+" 
                }

            catch{Write-Error $error[0].Exception}

            foreach($line in $content_array){

                if($line -match "(^[A-Z]:\\|^\\\\)\S+.*?"){

                    $custom_object = New-Object PSObject            
                    $custom_object | Add-Member -Name "Lnk File" -MemberType NoteProperty -Value $file        
                    $custom_object | Add-Member -Name "Disk Location" -MemberType NoteProperty -Value $line            
                    $custom_object | Add-Member -Name "OnDisk" -MemberType NoteProperty -Value $(Test-Path $line)
                    $out_array  += $custom_object
                    }
                  
                }
             
            }
         END{$out_array | Format-Table -AutoSize  }

            }
        



       
       
