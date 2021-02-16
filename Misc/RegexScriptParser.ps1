function Remove-PSScriptComments($FunctionBody)
{
    #Parse multi-line. each line needs to be treated as its own entity
    $Regex = [Regex]::new("<#(.+(`r`n|`n))+?#>", 'multiline')
    $ParsedNotes = [regex]::Matches($FunctionBody, $Regex ).value
    $res.ForEach({ $FunctionBody = $FunctionBody.replace($_,'') })
    return $FunctionBody
}
function Randomize-FunctionNames($FunctionBody)
{
    $Regex = [Regex]::new('(?<=function\s+).+?(?=\s+{)')
    $ParsedNames = [regex]::Matches($FunctionBody, $Regex).value
    foreach($Name in $ParsedNames)
    {
        $RandName = [System.IO.Path]::GetRandomFileName().split('.')[0]
        write-host "Replacing functin name $Name with $RandName" 
        $FunctionBody = $FunctionBody.replace($Name, $RandName)   
    }
    return $FunctionBody
}
