#Requires -Version 5.1
<#
  Готовит вход по ключу с Windows на VPS (один раз введёте пароль root).

  1) Запустите отсюда:
       cd c:\app\app\app
       .\deploy\prepare-ssh-from-windows.ps1

  2) Скопируйте выведенный публичный ключ на сервер (FileZilla → /root/.ssh/authorized_keys)
     ИЛИ выполните предложенную однострочную команду ssh-copy-id вручную в PowerShell
     после того как установите ключ (см. ниже).

  После этого: .\deploy\sync-htdocs.ps1
#>
param(
  [string]$RemoteHost = "185.98.7.61",
  [string]$RemoteUser = "root"
)

$ErrorActionPreference = "Stop"
$sshDir = Join-Path $env:USERPROFILE ".ssh"
$keyPath = Join-Path $sshDir "id_ed25519_sheber"
$pubPath = "$keyPath.pub"

if (-not (Test-Path -LiteralPath $sshDir)) {
  New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $keyPath)) {
  Write-Host "Creating key $keyPath ..."
  ssh-keygen -t ed25519 -f $keyPath -N '""' -C "sheber-deploy-windows"
}

$pub = Get-Content -Raw -LiteralPath $pubPath
Write-Host ""
Write-Host "=== Your public key (add to server /root/.ssh/authorized_keys) ===" -ForegroundColor Cyan
Write-Host $pub.TrimEnd()
Write-Host ""

$target = "${RemoteUser}@${RemoteHost}"
Write-Host "One-time (you type root password once):" -ForegroundColor Yellow
Write-Host "  type `"$pubPath`" | ssh $target `"mkdir -p .ssh && chmod 700 .ssh && cat >> .ssh/authorized_keys && chmod 600 .ssh/authorized_keys`""
Write-Host ""
Write-Host "Then use IdentityFile for deploy, or rename key to id_ed25519." -ForegroundColor Gray
Write-Host "Quick test:" -ForegroundColor Yellow
Write-Host "  ssh -i `"$keyPath`" $target `"echo ok`""
Write-Host ""
Write-Host "If ssh -i works, deploy htdocs with:" -ForegroundColor Green
Write-Host "  .\deploy\sync-htdocs.ps1 -IdentityFile `"$keyPath`""
