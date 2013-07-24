param ($isbn = $(Read-Host "ISBN"))
$ErrorActionPreference = "Stop"

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

[xml]$doc = & "$myPath\Invoke-AmazonApi.ps1" $parameter

$item = @($doc.ItemLookupResponse.Items.Item)[0]
$attrs = $item.ItemAttributes
$title = $attrs.Title
$authors = $attrs.Author
$isbn2 = $attrs.ISBN
$imgUrl = $item.LargeImage.URL

Write-Host "Title: $title"
Write-Host "Authors: $authors"
Write-Host "ISBN: $isbn2"

start $imgUrl

Write-Output $doc.OuterXml | Out-File "$myPath\result.xml"