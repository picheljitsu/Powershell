#PSScript to load VeraCryptDrive using PIM and Password
#

$veracrypt_path = "C:\Program Files\VeraCrypt\veracrypt.exe"
$drive = "Z"
$pim = read-host "PIM"
$pass = Read-Host "Password" -AsSecureString
$decpass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pass))


start-process $veracrypt_path -ArgumentList "/q /v \Device\Harddisk1\Partition3 /l Z /pim $pim /password `"$decpass`""
