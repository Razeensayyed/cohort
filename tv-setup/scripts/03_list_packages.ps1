# 03_list_packages.ps1 – Dump all packages and activities for review
# Paste the OUTPUT back to Claude so it can write a targeted debloat script.

$TV = "192.168.1.128:5555"

Write-Host "=== ALL PACKAGES ===" -ForegroundColor Cyan
adb -s $TV shell "pm list packages -3"    # Third-party / sideloaded
Write-Host ""
adb -s $TV shell "pm list packages -s"    # System packages

Write-Host "`n=== CURRENTLY DISABLED ===" -ForegroundColor Yellow
adb -s $TV shell "pm list packages -d"

Write-Host "`n=== SDK & BUILD ===" -ForegroundColor Cyan
adb -s $TV shell "getprop ro.build.version.sdk"
adb -s $TV shell "getprop ro.product.manufacturer"
adb -s $TV shell "getprop ro.product.model"
adb -s $TV shell "getprop ro.build.version.release"

Write-Host "`n=== HOME INTENT HANDLERS ===" -ForegroundColor Cyan
adb -s $TV shell "cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME"

Write-Host "`n=== USB STATE ===" -ForegroundColor Cyan
adb -s $TV shell "dumpsys usb | grep host_connected" 2>$null
adb -s $TV shell "dumpsys connectivity | grep -o 'Transports: [A-Z]*'" 2>$null

Write-Host "`nDone. Please paste the full output above back to Claude." -ForegroundColor Green
