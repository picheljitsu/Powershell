[xml]$xml = gc "U_Windows_2008_R2_MS_STIG_V1R23_Manual-xccdf.xml"
$stigchecks = foreach ($h in $xml.Benchmark){$h.Group.Rule.id | Sort-Object -Unique}

[xml]$xml2 = gc "U_Windows_2008_R2_MS_V1R26_STIG_SCAP_1-1_Benchmark-xccdf.xml"
$bmchecks = foreach ($h in $xml2.Benchmark) {$h.Group.Rule.id | Sort-Object -Unique}                                    

#This addresses your issue on having to filter the <,= characters.  Remember how I 
#said powershell has weird inconsistencies? This is one.  Accessing properties on
#PSCustomObject datatypes is different than accessing regular array/hashtables.
$diff = Compare-Object $bmchecks $stigchecks | select -ExpandProperty InputObject

#This array is used to dump the contents of the PSObject
$output_array = @()
foreach($i in $xml.Benchmark.Group){
    $vkey = $i | select -ExpandProperty rule | select -ExpandProperty id
    
    foreach ($x in $diff){
        if($x -eq $vkey){
            $custom_object = New-Object PSObject
            $custom_object | Add-Member -Name "ID" -MemberType NoteProperty -Value $i.id
            $custom_object | Add-Member -Name "Title" -MemberType NoteProperty -Value $i.Title
            $custom_object | Add-Member -Name "Sv-ID" -MemberType NoteProperty -Value $x
            $output_array += $custom_object
            }
        }
    }
$output_array | ft