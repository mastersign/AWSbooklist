param (
    $isbn = $(Read-Host "ISBN"), 
    $server = "ecs.amazonaws.com"
)
$myPath = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

$parameter = @{
    "Service" = "AWSECommerceService";
    "Version" = "2009-03-31";
    "Operation" = "ItemLookup";
    "ItemId" = $isbn;
    "IdType" = "ISBN";
    "SearchIndex" = "Books";
    "ResponseGroup" = "ItemAttributes,Images" 
    }

[xml]$doc = & "$myPath\Invoke-AmazonApi.ps1" $parameter -server $server

if (!$doc) { return $null }

#$doc.OuterXml | Out-File "$myPath\$isbn.xml"

$foundError = $false
foreach ($error in $doc.ItemLookupResponse.Items.Request.Errors.Error) {
  Write-Warning $error.Message
  $foundError = $true
}
if ($foundError) { return $null }

$item = @($doc.ItemLookupResponse.Items.Item)[0]
$attrs = $item.ItemAttributes
if (!$attrs) { return $null }
$lang = @($attrs.Languages.Language) | ? { $_.Type -eq "Published" } | % { $_.Name }

$result = @{}
$result.Add("ASIN", $item.ASIN)
$result.Add("DetailsUrl", $item.DetailPageURL)
$result.Add("ISBN", $attrs.ISBN)
$result.Add("EAN", $attrs.EAN)
$result.Add("Title", $attrs.Title)
$result.Add("Authors", @($attrs.Author))
$result.Add("Binding", $attrs.Binding)
$result.Add("Pages", $attrs.NumberOfPages)
$result.Add("Publisher", $attrs.Publisher)
$result.Add("PublicationDate", $attrs.PublicationDate)
$result.Add("PublicationLanguage", $lang)
$result.Add("SmallImageUrl", $item.SmallImage.URL)
$result.Add("MediumImageUrl", $item.MediumImage.URL)
$result.Add("LargeImageUrl", $item.LargeImage.URL)

return $result
