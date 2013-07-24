param(
  $arguments,
  $protocol = "https", 
  $server = "ecs.amazonaws.com", 
  $path = "/onca/xml"
)

$myPath = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
if (-not (Test-Path "$myPath\aws.config.ps1")) {
  throw "No AWS configuration found. Use the template to create the aws.config.ps1 file."
  return $null
}
. $myPath\aws.config.ps1

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Security.Cryptography") | Out-Null

function url-encode($value) {
    if ($value -eq $null) { $value = "" }
    $encoded = [System.Web.HttpUtility]::UrlEncode($value.ToString())
    $encoded = $encoded.Replace("'", "%27").Replace("(", "%28").Replace(")", "%29").Replace("*", "%2A").Replace("!", "%21").Replace("%7e", "~").Replace("+", "%20")
    $pattern = [regex]"%.."
    $m = $pattern.Match($encoded)
    while ($m.Success) {
        $encoded = $encoded.Substring(0, $m.Index) + `
                    $m.Value.ToUpper() + `
                    $encoded.Substring($m.Index + $m.Length)
        $m = $pattern.Match($encoded, $m.Index + $m.Length)
    }
    return $encoded
}

function get-ordinal-string($value) {
    $res = ""
    foreach ($c in $value.ToCharArray()) {
        $res += ([int]$c).ToString("X4")
    }
    return $res
}

function sort-ordinal($values) {
    $ordinals = @($values | % { get-ordinal-string $_ })
    $valueArr = @($values)
    [Array]::Sort($ordinals, $valueArr)
    return $valueArr
}

function build-query-string($arguments) {
    $res = ""
    $keys = sort-ordinal ($arguments.Keys)
    foreach ($key in $keys) {
        if ($res.Length -gt 0) { $res += "&" }
        $res += (url-encode $key) + "=" + (url-encode $arguments[$key])
    }
    return $res
}

function build-signing-content($server, $path, $arguments) {
    $res = "GET`n"
    $res += "$server`n"
    $res += $path + "`n"
    $res += build-query-string $arguments
    return [Text.Encoding]::UTF8.GetBytes($res)
}

function compute-hmac-sha256($data, $key) {
    $keyData = [Text.Encoding]::UTF8.GetBytes($key)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256 (,$keyData)
    $sigData = $hmac.ComputeHash($data)
    $sig = [Convert]::ToBase64String($sigData)
    return $sig
}

$server = $server.ToLower()
if ([string]::IsNullOrEmpty($path)) { $path = "/" }

$allargs = @{}
foreach ($key in $arguments.Keys) { $allargs.Add($key, $arguments[$key]) }
$allargs.Add("AWSAccessKeyId", $awsAccessKey)
$allargs.Add("AssociateTag", $awsAssociateId)
$allargs.Add("Timestamp", [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"))
$allargs.Add("SignatureVersion", "2")
$allargs.Add("SignatureMethod", "HmacSHA256")
$query = build-query-string $allargs
$signingData = build-signing-content $server $path $allargs
$signature = compute-hmac-sha256 $signingData $awsPrivateKey
$query += "&Signature=" + (url-encode $signature)
$url = "${protocol}://${server}${path}?${query}"

$result = Invoke-RestMethod $url
return $result