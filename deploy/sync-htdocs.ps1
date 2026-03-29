#Requires -Version 5.1
<#
.SYNOPSIS
  Копирует c:\app\app\app\htdocs на VPS (DuckDNS / sheberkz.duckdns.org), не затирая config.local.php на сервере.

  Требования: OpenSSH Client (scp, ssh) в Windows.

  Пример:
    .\deploy\sync-htdocs.ps1
    .\deploy\sync-htdocs.ps1 -RemotePath "/var/www/sheber"
    .\deploy\sync-htdocs.ps1 -IdentityFile "$env:USERPROFILE\.ssh\id_ed25519_sheber"
#>
param(
  [string]$RemoteHost = "185.98.7.61",
  [string]$RemoteUser = "root",
  [string]$RemotePath = "/var/www/sheber",
  [int]$SshPort = 22,
  [string]$Htdocs = "",
  [string]$IdentityFile = ""
)

$ErrorActionPreference = "Stop"
if ($Htdocs -eq "") {
  $Htdocs = Join-Path (Split-Path $PSScriptRoot -Parent) "htdocs"
}
if (-not (Test-Path -LiteralPath $Htdocs)) {
  throw "htdocs folder not found: $Htdocs"
}
if ($IdentityFile -ne "" -and -not (Test-Path -LiteralPath $IdentityFile)) {
  throw "IdentityFile not found: $IdentityFile"
}

function Get-SshArgs {
  $a = @()
  if ($IdentityFile -ne "") { $a += "-i", $IdentityFile }
  if ($SshPort -ne 22) { $a += "-p", "$SshPort" }
  return ,$a
}
function Get-ScpArgs {
  $a = @()
  if ($IdentityFile -ne "") { $a += "-i", $IdentityFile }
  if ($SshPort -ne 22) { $a += "-P", "$SshPort" }
  return ,$a
}

$stage = Join-Path $env:TEMP ("sheber-htdocs-" + (Get-Date -Format "yyyyMMddHHmmss"))
New-Item -ItemType Directory -Force -Path $stage | Out-Null
try {
  # /E: recursive; no /MIR: do not delete extra files on server (uploads etc.)
  # /XD .claude: IDE junk
  # /XF config.local.php: never overwrite server secrets on redeploy
  $null = robocopy $Htdocs $stage /E /NFL /NDL /NJH /NJS /NP `
    /XD .claude `
    /XF config.local.php

  if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE"
  }

  $sshTarget = "{0}@{1}" -f $RemoteUser, $RemoteHost
  $mk = "mkdir -p '" + $RemotePath.TrimEnd("/") + "'"
  $sshArgs = Get-SshArgs
  & ssh @sshArgs $sshTarget $mk
  if ($LASTEXITCODE -ne 0) { throw "ssh mkdir failed (exit $LASTEXITCODE)" }

  $scpTarget = "{0}:{1}/" -f $sshTarget, $RemotePath.TrimEnd("/")

  Write-Host "scp -> $scpTarget (port $SshPort) ..."
  $scpArgs = @(Get-ScpArgs) + @("-r", "$stage\*", $scpTarget)
  & scp @scpArgs
  if ($LASTEXITCODE -ne 0) { throw "scp failed (exit $LASTEXITCODE)" }

  Write-Host "Fixing permissions (dirs traversable by nginx www-data, uploads writable) ..."
  $rp = $RemotePath.TrimEnd("/")
  $fix = "chown -R www-data:www-data '$rp/uploads' '$rp/storage' 2>/dev/null; chmod -R ug+rwX '$rp/uploads' '$rp/storage' 2>/dev/null; find '$rp' -type d -exec chmod a+rx {} \; 2>/dev/null; true"
  & ssh @sshArgs $sshTarget $fix
  if ($LASTEXITCODE -ne 0) { throw "ssh chmod failed (exit $LASTEXITCODE)" }

  Write-Host "Done. Test: curl -sS https://sheberkz.duckdns.org/api/ping.php"
} finally {
  Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
}
