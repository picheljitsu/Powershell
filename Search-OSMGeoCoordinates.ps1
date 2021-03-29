function Search-OSMGeoCoordinates
{
    <#
        .SYNOPSIS
            Performs a Geocoodinate lookup to the Nominatim Search API endpoint
            Author: n0perator
            
        .DESCRIPTION
            Builds a set of URI parameters that are defined by the API and performs
            a query to the "search" endpoing at nominatim.openstreetmap.org.
            
        .PARAMETER Query
            Specifies a query to search and is an alternative to the specific parameters listed
            below this parameter.
            
        .PARAMETER Street
            Specifies the street name.  The structure should be <housenumber> <streetname>
            
        .PARAMETER City
            Secifies the city to search.
            
        .PARAMETER County
            Secifies the county to search.
            
        .PARAMETER State
            Secifies the state to search.  This parameter can be the full name or two-letter 
            state abbreviation
            
        .PARAMETER Country
            Secifies the state to search. This parameter can be the full name or abbreviation
            
        .PARAMETER Postalcode
            Secifies the postal code using the shorthand 5-digit or full code
            
        .PARAMETER Format
            JSON is the defualt output if a format is specified. Acceptable formats are listed in the notes section.
            
        .PARAMETER WebRequestParams
            Specifies a hashtable of parameters to pass to Invoke-WebRequest. Useful if you need to specify a proxy or
            credentials when performing the web request.
            
        .EXAMPLE
            Search-OSMGeoCoordinates -query "Orlando, FL"
            returns a Powershell object
            
        .EXAMPLE
            Search-OSMGeoCoordinates -query "Orlando, FL" -format json
            returns a JSon object
            
        .EXAMPLE 
            Search-OSMGeoCoordinates -City "Orlando" -State "FL" -Country "United States"
            
        .EXAMPLE             
            $RequestParams = @{ Proxy ='http://<proxy_address>:<port>'; ProxyUseDefaultCredentials = $True}
            Search-OSMGeoCoordinates -City "Orlando" -state "FL" -Country "United States" -WebRequestParams $RequestParams
            
        .NOTES
            If a query is too specific, it may not return results. Broadening the search by removing certain parameters may
            help.
            Query format: https://nominatim.openstreetmap.org/search?<params>
            Use the Verbose parameter to view resulting URI query string.
            Params:
                q=<query>
                street=<housenumber> <streetname>       
                city=<city>
                county=<county>
                state=<state>
                country=<country>
                postalcode=<postalcode>
                street=<housenumber> <streetname>
            Supported output formats: xml|json|jsonv2|geojson|geocodejson
            
        .LINK
            https://nominatim.org/release-docs/develop/api/Search/
    #>
    [CmdletBinding(DefaultParameterSetName='Detailed')]Param(
        [Parameter(ParameterSetName='Query',    Position=0)][Alias("Query")][String]$Q,        
        [Parameter(ParameterSetName='Detailed', Position=0)][String]$Street,
        [Parameter(ParameterSetName='Detailed', Position=1)][String]$City,
        [Parameter(ParameterSetName='Detailed', Position=2)][String]$County,
        [Parameter(ParameterSetName='Detailed', Position=3)][String]$State,
        [Parameter(ParameterSetName='Detailed', Position=4)][String]$Country,
        [Parameter(ParameterSetName='Detailed', Position=5)][String]$Postalcode,
        [Parameter(ParameterSetName='Detailed', Mandatory=$False, Position=6)]
        [Parameter(ParameterSetName='Query', Mandatory=$False, Position=1)]
            [ValidateSet("psobject","xml","json","jsonv2","geojson","geocodejson")][String]$Format,
        [Parameter(Mandatory=$False)][Hashtable]$WebRequestParams
        )
        
    #Parse out Parameter names, excluding built-in
    $Caller = Get-Command $($PSCmdlet.MyInvocation.InvocationName)
    $Allkeys = [array]$Caller.Parameters.keys
    
    #Any parameter not given a ParameterSetName falls under __AllParameterSets
    $ParamKeys = $Allkeys.where({ $Caller.parameters[$_].ParameterSets.keys -ne '__AllParameterSets'  })
    $Keys = [array]$PSBoundParameters.keys.Where({ $_ -in $ParamKeys })
    
    #Format the parameter keys & values for the URI request
    $Params = $keys.ForEach({ "$_=$($PSBoundParameters[$_].replace(' ','+'))" })
    
    #Build the compiled URI search parameters
    $UriParams=  $($Params -join "&").ToLower()
    $SearchUri = 'https://nominatim.openstreetmap.org/search?{0:s}' -f $UriParams
    
    #If format isn't specified, use json for the request, but return a PSObject
    if($UriParams -inotmatch 'format')
    {       
        $SearchUri += "&format=json"
        return $((Invoke-WebRequest -Uri $SearchUri @WebRequestParams).content | ConvertFrom-Json)
    }
    else
    {
        return $(Invoke-WebRequest -Uri $SearchUri @WebRequestParams).content
    }
}
