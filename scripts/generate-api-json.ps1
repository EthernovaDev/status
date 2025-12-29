$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$summaryPath = Join-Path $repoRoot "history\\summary.json"
$upptimePath = Join-Path $repoRoot ".upptimerc.yml"
$apiDir = Join-Path $repoRoot "api"

if (-not (Test-Path $summaryPath)) {
  throw "history/summary.json not found"
}

$summaryRaw = Get-Content -Raw -Path $summaryPath
$summary = $summaryRaw | ConvertFrom-Json

if (-not (Test-Path $apiDir)) {
  New-Item -ItemType Directory -Path $apiDir | Out-Null
}

Set-Content -Path (Join-Path $apiDir "summary.json") -Value ($summary | ConvertTo-Json -Depth 10) -NoNewline

$lines = Get-Content -Path $upptimePath

function Trim-YamlValue {
  param([string]$Value)
  if ($null -eq $Value) { return $null }
  $v = $Value.Trim()
  if (($v.StartsWith('"') -and $v.EndsWith('"')) -or ($v.StartsWith("'") -and $v.EndsWith("'"))) {
    $v = $v.Substring(1, $v.Length - 2)
  }
  return $v
}

$ownerLine = $lines | Where-Object { $_ -match "^\s*owner:\s*" } | Select-Object -First 1
$repoLine = $lines | Where-Object { $_ -match "^\s*repo:\s*" } | Select-Object -First 1
$owner = Trim-YamlValue ($ownerLine -replace "^\s*owner:\s*", "")
$repo = Trim-YamlValue ($repoLine -replace "^\s*repo:\s*", "")

$baseUrl = $null
$theme = $null
$name = $null
$introTitle = $null
$introMessage = $null
$navbar = @()
$inStatusWebsite = $false
$inNavbar = $false
$currentNav = $null

foreach ($line in $lines) {
  if ($line -match "^\s*status-website:\s*$") {
    $inStatusWebsite = $true
    $inNavbar = $false
    continue
  }
  if ($inStatusWebsite -and $line -match "^\S") {
    $inStatusWebsite = $false
    $inNavbar = $false
    continue
  }
  if (-not $inStatusWebsite) { continue }

  if ($line -match "^\s{2}navbar:\s*$") {
    $inNavbar = $true
    continue
  }

  if ($inNavbar) {
    if ($line -match "^\s{2}[A-Za-z0-9_-]+:\s*") {
      $inNavbar = $false
    }
  }

  if ($inNavbar) {
    if ($line -match "^\s{4}-\s+title:\s*(.+)$") {
      $currentNav = [ordered]@{ title = (Trim-YamlValue $matches[1]) }
      $navbar += $currentNav
      continue
    }
    if ($line -match "^\s{6}href:\s*(.+)$" -and $null -ne $currentNav) {
      $currentNav.href = Trim-YamlValue $matches[1]
      continue
    }
  } else {
    if ($line -match "^\s{2}baseUrl:\s*(.+)$") { $baseUrl = Trim-YamlValue $matches[1]; continue }
    if ($line -match "^\s{2}theme:\s*(.+)$") { $theme = Trim-YamlValue $matches[1]; continue }
    if ($line -match "^\s{2}name:\s*(.+)$") { $name = Trim-YamlValue $matches[1]; continue }
    if ($line -match "^\s{2}introTitle:\s*(.+)$") { $introTitle = Trim-YamlValue $matches[1]; continue }
    if ($line -match "^\s{2}introMessage:\s*(.+)$") { $introMessage = Trim-YamlValue $matches[1]; continue }
  }
}

$statusWebsite = [ordered]@{}
if ($baseUrl) { $statusWebsite.baseUrl = $baseUrl }
if ($theme) { $statusWebsite.theme = $theme }
if ($name) { $statusWebsite.name = $name }
if ($introTitle) { $statusWebsite.introTitle = $introTitle }
if ($introMessage) { $statusWebsite.introMessage = $introMessage }
if ($navbar.Count -gt 0) { $statusWebsite.navbar = $navbar }

$sites = @()
foreach ($item in $summary) {
  $sites += [ordered]@{
    name = $item.name
    url = $item.url
    slug = $item.slug
    status = $item.status
  }
}

$statusPage = [ordered]@{
  owner = $owner
  repo = $repo
  sites = $sites
  "status-website" = $statusWebsite
}

Set-Content -Path (Join-Path $apiDir "status-page.json") -Value ($statusPage | ConvertTo-Json -Depth 8) -NoNewline
