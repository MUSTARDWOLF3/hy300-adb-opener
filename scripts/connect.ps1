# Windows helper: finds the projector's TLS ADB port over mDNS and connects.
# Requires platform-tools (adb) on PATH, or edit $adb below.

$adb = "adb"  # or an absolute path: "C:\path\to\platform-tools\adb.exe"

Write-Host "Searching for ADB via mDNS..."
$lines = & $adb mdns services 2>&1 | Select-String "_adb-tls-connect._tcp"
if (-not $lines) {
    Write-Host "No ADB service found. Make sure the HY300 ADB Opener app ran successfully"
    Write-Host "on the projector, and that both are on the same Wi-Fi."
    exit 1
}

foreach ($line in $lines) {
    if ($line -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)") {
        $ip = $Matches[1]
        $port = $Matches[2]
        Write-Host "Found $ip`:$port"
        Write-Host "Connecting..."
        & $adb connect "$ip`:$port"
        & $adb devices -l
        exit 0
    }
}

Write-Host "Could not parse mDNS output."
exit 1
