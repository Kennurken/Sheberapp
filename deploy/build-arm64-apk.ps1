#Requires -Version 5.1
<#
.SYNOPSIS
  Собирает release APK только для arm64-v8a и копирует в dist\ (без копирования всей папки build).

.EXAMPLE
  .\deploy\build-arm64-apk.ps1
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$AppDir = Join-Path $Root "sheber_app"
$OutDir = Join-Path $Root "dist\android-arm64-v8a"
$BuiltApk = Join-Path $AppDir "build\app\outputs\flutter-apk\app-release.apk"
$DestName = "sheberkz-arm64-v8a-release.apk"
$Dest = Join-Path $OutDir $DestName

Push-Location $AppDir
try {
  flutter build apk --release --target-platform android-arm64
  if ($LASTEXITCODE -ne 0) { throw "flutter build failed with exit code $LASTEXITCODE" }
} finally {
  Pop-Location
}

if (-not (Test-Path -LiteralPath $BuiltApk)) {
  throw "APK not found: $BuiltApk"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Copy-Item -LiteralPath $BuiltApk -Destination $Dest -Force
Write-Host "OK: $Dest"
