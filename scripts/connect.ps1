# Windows helper: finds the projector's TLS ADB port over mDNS and connects.
#
# Requires platform-tools (adb). The script tries, in order:
#   1. An $env:ADB environment variable, if you set it.
#   2. adb.exe on your PATH.
#   3. A few common install locations (Android SDK, Downloads\platform-tools).
#
# If none of those works, download platform-tools from
# https://developer.android.com/tools/releases/platform-tools
# and either add it to PATH or set $env:ADB to the full path to adb.exe.

$ErrorActionPreference = 'Stop'

function Find-Adb {
    if ($env:ADB -and (Test-Path $env:ADB)) { return $env:ADB }
    $onPath = Get-Command adb -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    $candidates = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools\adb.exe",
        "$env:USERPROFILE\Downloads\platform-tools-latest-windows\platform-tools\adb.exe",
        "C:\platform-tools\adb.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

$adb = Find-Adb
if ($null -eq $adb) {
    Write-Host 'ERROR: Could not find adb.exe.' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Install Android platform-tools:'
    Write-Host '  https://developer.android.com/tools/releases/platform-tools'
    Write-Host ''
    Write-Host 'Then either:'
    Write-Host '  - Add it to your PATH, or'
    Write-Host '  - Run this script after: $env:ADB = "C:\full\path\to\adb.exe"'
    exit 2
}
Write-Host "Using adb: $adb"

Write-Host 'Searching for ADB via mDNS...'
$lines = & $adb mdns services 2>&1 | Select-String '_adb-tls-connect._tcp'
if (-not $lines) {
    Write-Host 'No ADB service found.' -ForegroundColor Yellow
    Write-Host 'Make sure the HY300 ADB Opener app ran successfully on the projector,'
    Write-Host 'and that both are on the same Wi-Fi.'
    exit 1
}

foreach ($line in $lines) {
    if ($line -match '(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)') {
        $target = $Matches[0]
        Write-Host "Found $target" -ForegroundColor Green
        Write-Host 'Connecting...'
        & $adb connect $target
        & $adb devices -l
        exit 0
    }
}

Write-Host 'Could not parse mDNS output.' -ForegroundColor Red
exit 1
