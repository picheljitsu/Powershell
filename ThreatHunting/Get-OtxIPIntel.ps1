function Get-OtxIPIntel
{

    #URI Parameters
    #ip: required (string)
    #Example:
    #8.8.8.8
    #section: required (one of general, reputation, geo, malware, url_list, passive_dns)

    [CmdletBinding()]param(
        [parameter(Mandatory=$True,Position=0)][IPaddress[]]$IPv4,
        [parameter(Mandatory=$True,Position=1)]
            [ValidateSet('general', 'reputation', 'geo', 'malware', 'url_list', 'passive_dns')][String[]]$Section,   #Make this array?
        [parameter(Mandatory=$True,Position=3)][String]$OtxApiKey,
        [parameter(Mandatory=$False)][Switch]$JSON
    )
    BEGIN
    {
        $Endpoint = 'https://otx.alienvault.com/api/v1/indicators/IPv4/{0:s}/{1:s}'        
        $Creds = @{ 'username' = $OtxApiKey; 'password' = 'notrequired '}
        $Params = @{ Method = 'GET' ; Headers = $Creds }
        $Results = @()
    }
    PROCESS
    {
        for($ip=0;$ip -lt $IPv4.Count; $ip++)
        {        
            for($sect=0;$sect -lt $sect.count; $sect++)
            {
                try 
                {
                    write-verbose "Performing lookup on IP: $($IPv4[$ip])"
                    $Content = Invoke-RestMethod -Uri $($Endpoint -f @($IPv4[$ip], $Section[$sect])) @Params                                     
                    $Results += $Content                    
                }
                catch 
                {
                "FUCK"    
                }
                
            }
        }
    }
    END
    {
        return $Results
    }
}
