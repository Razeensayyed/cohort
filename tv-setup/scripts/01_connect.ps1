# 01_connect.ps1 – Connect ADB to OnePlus TV Y series
# Run from tv-setup\scripts\ in PowerShell (as Administrator)

$TV_IP   = "192.168.1.128"
$TV_PORT = "5555"

Write-Host "Connecting to $TV_IP`:$TV_PORT ..." -ForegroundColor Cyan

adb connect "$TV_IP`:$TV_PORT"

# Give it a moment and check
Start-Sleep -Seconds 2
$devices = adb devices
Write-Host $devices

if ($devices -match $TV_IP) {
    Write-Host "`n[OK] Connected to TV." -ForegroundColor Green
    Write-Host "IMPORTANT: Watch the TV screen now — accept the 'Allow USB debugging?' prompt if it appears." -ForegroundColor Yellow
    Start-Sleep -Seconds 3

    $model = adb -s "$TV_IP`:$TV_PORT" shell "getprop ro.product.model"
    $sdk   = adb -s "$TV_IP`:$TV_PORT" shell "getprop ro.build.version.sdk"
    Write-Host "`nTV model : $model" -ForegroundColor Cyan
    Write-Host "SDK level: $sdk (Android $( [int]$sdk - 19 + 5 ) roughly)" -ForegroundColor Cyan
} else {
    Write-Host "`n[FAIL] Could not connect. Check:" -ForegroundColor Red
    Write-Host "  1. TV and PC are on the same Wi-Fi"
    Write-Host "  2. Developer options > USB debugging and Network/ADB debugging are both ON"
    Write-Host "  3. No firewall blocking port 5555"
}
