$RepoTreeUri = 'https://<server>/api/v4/projects/<url-encoded_project_name>/repository/tree'
$Branch = 'master' #Set your branch
$ModulesPath = 'modules'
$Recursion = $True
$PageCount = '100'
$RepoTreeParams = '?ref={0:s}&path={1:s}&recursive={2:s}&per_page={3:s}'

$FileTreeUri = $RepoTreeUri + $RepoTreeParams

$WebClient = [System.Net.Webclient]::new()
$WebClient.Headers.Add('PRIVATE-TOKEN',$Token)
$JSONResponse = $WebClient.DownloadString($FileTreeUri) | ConvertFrom-JSON
