function Get-RegistryRunMRU{

    <# 
    .Synopsis 
        Gets the RunMRU registry key values for a given user 

    .Description
        Mounts the user's NTUSER.DAT file and extracts the RunMRU Keys and returns a hash
        table of values.

    .Example
        Get-RegistryRunMRU -UserName <username>

    .Example
        Get-RegistryRunMRU -UserName <username> -ComputerName <host name>

    .Example 
        Get-RegistryRunMRU -UserName <username>  -Dismount
    
    .Notes        
        Author : Matt Pichelmayer
        License: BSD 3-Clause
    #> 

    [Cmdletbinding()]

    Param([Parameter][string]$ComputerName) 
    DynamicParam

        {

        $ParameterName = 'UserName'
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1
        $AttributeCollection.Add($ParameterAttribute)
        $arrSet = (Get-ChildItem -Path C:\users).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

        return $RuntimeParameterDictionary

        }

    BEGIN { $UserName = $PsBoundParameters[$ParameterName] }

    PROCESS {

        $newname = $($UserName.replace(".",""))
        $hive = "HKU\$newname"

        #check if the ComputerName argument was supplied and set the drive to the remote location
        if($ComputerName){ $drive_location = "\\$ComputerName\C$" }

        #Otherwise load a local user's registry
        else{$drive_location = "$($env:systemdrive)"}

        $path = "$drive_location\Users\$UserName\ntuser.dat"
        Test-Path $path -ErrorAction Stop | Out-Null

        try{ reg load $hive $path | Out-Null }

        catch { "[-] Couldn't load user's HIVE." }

        try{ $RetVal = New-PSDrive -Name $newname `
                                   -PSProvider Registry `
                                   -Root $hive `
                                   -Scope Global `
                                   -ErrorAction Stop  }

        catch{  if($error[0].Exception -like "*already exists.*"){

                    if($UserName -in (Get-PSDrive).name){

                        write-host "[!] Drive $UserName`: already mounted."

                        }

                    }

              }

        $MRUList = "$($newname):\Software\Microsoft\Windows\CurrentVersion\Explorer"

        if(Test-Path $MRUList){

            write-host "`nRegistry Location: $MRUList"
            write-host "-----------------------------------"
            Set-Location $MRUList -ErrorAction Stop

            $MRUProperties = Get-ItemProperty "RunMRU"
            $MRUArray = ($MRUProperties | select -ExpandProperty MRUList) -split ""

            foreach($property in $MRUArray){

                if($property){ $Output += @{ $property = $(($MRUProperties.$property).tostring()).trimend("\1") } }

                }

            }
            
        else { write-host "[-] Couldn't find registry key $MRUList" }

        Set-Location -Path "C:\"
        reg unload $hive
        Remove-PSDrive -Name $newname

        }

    END { return $Output }

    }
