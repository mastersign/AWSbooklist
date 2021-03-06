param (
  $listFile, 
  $targetFile = $null,
  $server = "ecs.amazonaws.com",
  [switch]$noFragment, 
  [switch]$noStyles
)

$myPath = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

if ([string]::IsNullOrEmpty($targetFile)) {
  $targetFile = [IO.Path]::Combine([IO.Path]::GetDirectoryName($listFile), `
                [IO.Path]::GetFileNameWithoutExtension($listFile) + ".html")
}

$w_Authors = "From"
$w_Publisher = "Publisher"
$w_PublicationDate ="Published"
$w_PublicationLanguage = "Language"
$w_Pages = "Pages"
$w_Binding = "Binding"
$w_ISBN = "ISBN"
$w_EAN = "EAN"

$list = Get-Content $listFile

$res = ""
if ($noFragment) {
    $res = "<!DOCTYPE html>`n"
    $res += "<html>`n"
    $res += "<head>`n"
    $res += "  <meta charset=`"utf-8`">`n"
    $res += "  <title>Book List</title>`n"
}

if (!$noStyles) {
    $res += "<style type=`"text/css`">
.booklist-item { margin-bottom: 1em; }
.booklist-image { float: left; }
.booklist-description { margin-left: 180px; }
.booklist-title { font-weight: bold; margin-bottom: 0.25em; }
.booklist-authors { font-style: italic; margin-bottom: 0.25em; }
.booklist-detail { font-size: smaller; }
</style>`n"
}

if ($noFragment) {
    $res += "</head>`n"
    $res += "<body>`n"
    $res += "<h1>Book List</h1>`n"
}

function normalize-isbn($isbn) {
  $isbn = $isbn.Trim()
  if (($isbn.Length -eq 0) -or ($isbn.StartsWith("#"))) { continue }
  $isbn = $isbn.Replace(" ", "").Replace("-", "")
  return $isbn
}

function count() {
  begin {
    $n = 0
  }
  process {
    $n = $n + 1
  }
  end {
    return $n
  }
}

function info-fitness($info) {
  return $info.Values | ? { ![string]::IsNullOrEmpty($_) } | count
}

function best-info($infos) {
  $res = $null
  $max_fit = 0
  foreach ($info in $infos) {
    $fit = info-fitness $info
    # Write-Host "Fitness for $($info.Title) from $($info.Source): $fit"
    if ($fit -gt $max_fit) {
      $max_fit = $fit
      $res = $info
    }
  }
  return $res
}

function get-info($svr, $isbn) {
  if ($svr -is [array]) {
    $infos = @()
    foreach ($s in $svr) {
      $info = & "$myPath\Get-BookInfo.ps1" -isbn $isbn -server $s
      if (!$info) { continue }
      $info.Add("Source", $s)
      $infos += $info
    }
    return best-info $infos
  } else {
    return & "$myPath\Get-BookInfo.ps1" -isbn $isbn -server $svr
  }
}

foreach($isbn in $list) {
  if ($isbn -eq $null) { continue }
  $isbn = normalize-isbn $isbn
  $info = get-info $server $isbn
 
  if (!$info) {
    Write-Warning "Could not obtain information about $isbn."
    continue
  }
  
  $authors = [string]::Join(", ", $info.Authors)
  
  $res += "<div id=`"book_$($info.ASIN)`" class=`"booklist-item`">`n"
  $res += "  <img src=`"$($info.MediumImageUrl)`" class=`"booklist-image`" alt=`"Cover Picture`" />`n"
  $res += "  <div class=`"booklist-description`">`n"
  $res += "    <div class=`"booklist-title`"><a href=`"$($info.DetailsUrl)`" target=`"_blank`">$($info.Title)</a></div>`n"
  $res += "    <div class=`"booklist-authors`">${w_Authors}: $authors</div>`n"
  if ($info.Publisher) {
    $res += "    <div class=`"booklist-detail`">${w_Publisher}: $($info.Publisher)</div>`n"
  }
  if ($info.PublicationDate) {
    $res += "    <div class=`"booklist-detail`">${w_PublicationDate}: $($info.PublicationDate)</div>`n"
  }
  if ($info.PublicationLanguage) {
    $res += "    <div class=`"booklist-detail`">${w_PublicationLanguage}: $($info.PublicationLanguage)</div>`n"
  }
  if ($info.Pages) {
    $res += "    <div class=`"booklist-detail`">${w_Pages}: $($info.Pages)</div>`n"
  }
  if ($info.Binding) {
    $res += "    <div class=`"booklist-detail`">${w_Binding}: $($info.Binding)</div>`n"
  }
  $res += "    <div class=`"booklist-detail`">${w_ISBN}: $($info.ISBN)</div>`n"
  $res += "    <div class=`"booklist-detail`">${w_EAN}: $($info.EAN)</div>`n"
  $res += "  </div>`n"
  $res += "  <div style=`"clear: left;`"></div>`n"
  $res += "</div>`n"
}

if ($noFragment) {
    $res += "</body>`n"
    $res += "</html>`n"
}

$res | Out-File $targetFile -Encoding utf8
