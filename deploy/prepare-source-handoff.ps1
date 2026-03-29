#Requires -Version 5.1
<#
.SYNOPSIS
  Собирает папку SheberKZ_source_handoff/ для передачи коллеге: исходники без build, .dart_tool, секретов.

.EXAMPLE
  .\deploy\prepare-source-handoff.ps1
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$dest = Join-Path $Root "SheberKZ_source_handoff"

if (Test-Path $dest) {
  Remove-Item -LiteralPath $dest -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$null = robocopy (Join-Path $Root "sheber_app") (Join-Path $dest "sheber_app") /E /NFL /NDL /NJH /NJS /NP `
  /XD build .dart_tool Pods .symlinks ephemeral .gradle `
  /XF local.properties

$null = robocopy (Join-Path $Root "htdocs") (Join-Path $dest "htdocs") /E /NFL /NDL /NJH /NJS /NP /XF config.local.php

$null = robocopy (Join-Path $Root "deploy") (Join-Path $dest "deploy") /E /NFL /NDL /NJH /NJS /NP

foreach ($f in @("CLAUDE.md", "SHEBER_CONTEXT.md", "SHEBER_CURSOR_HANDOFF.md")) {
  $src = Join-Path $Root $f
  if (Test-Path $src) {
    Copy-Item -LiteralPath $src -Destination (Join-Path $dest $f) -Force
  }
}
$gs = Join-Path $Root "google-services.json"
if (Test-Path $gs) {
  Copy-Item -LiteralPath $gs -Destination (Join-Path $dest "google-services.json") -Force
}

# Убрать то, что robocopy мог пропустить по имени каталога
$app = Join-Path $dest "sheber_app"
Remove-Item -LiteralPath (Join-Path $app ".dart_tool") -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $app "android\local.properties") -Force -ErrorAction SilentlyContinue
Get-ChildItem -Path $app -Recurse -Directory -Filter "ephemeral" -ErrorAction SilentlyContinue |
  ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }

$readme = @"
SHEBER.KZ — исходники для коллеги
================================

Внутри:
  sheber_app/   — Flutter (Dart), без build и .dart_tool
  htdocs/       — PHP API (config.local.php не включён)
  deploy/       — деплой и build-arm64-apk.ps1
  CLAUDE.md, SHEBER_CONTEXT.md, SHEBER_CURSOR_HANDOFF.md
  google-services.json

Перед сборкой: cd sheber_app && flutter pub get && flutter run
Сервер: скопировать htdocs/config.local.example.php -> config.local.php

Сборка APK: из корня репозитория после распаковки — .\deploy\build-arm64-apk.ps1
"@
$readme | Set-Content -LiteralPath (Join-Path $dest "README_HANDOFF.txt") -Encoding UTF8

Write-Host "OK: $dest"
