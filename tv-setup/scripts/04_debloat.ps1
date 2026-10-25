# 04_debloat.ps1 – Debloat OnePlus TV Y series
# Run AFTER 02_backup.ps1. Disables in small batches with confirmation.
# Re-enable everything with tv-setup\restore_data\restore_*.ps1

$TV = "192.168.1.128:5555"

function Disable-Batch {
    param(
        [string]$Category,
        [string[]]$Packages
    )
    Write-Host "`n=== $Category ===" -ForegroundColor Yellow
    foreach ($pkg in $Packages) {
        Write-Host "  $pkg"
    }
    $confirm = Read-Host "Disable this batch? [y/N]"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "  Skipped." -ForegroundColor Gray
        return
    }
    foreach ($pkg in $Packages) {
        Write-Host "  Disabling $pkg ..." -NoNewline
        $result = adb -s $TV shell "pm disable-user --user 0 $pkg" 2>&1
        if ($result -match "disabled") {
            Write-Host " OK" -ForegroundColor Green
            # Append to restore script
            $restoreFiles = Get-ChildItem "$PSScriptRoot\..\restore_data\restore_*.ps1" | Sort-Object LastWriteTime -Descending
            if ($restoreFiles) {
                $restoreFile = $restoreFiles[0].FullName
                # Insert package into the array in restore script
                (Get-Content $restoreFile) -replace '(# Filled in by 04_debloat.*)', "`$1`n    `"$pkg`"," |
                    Set-Content $restoreFile
            }
        } elseif ($result -match "Unknown package") {
            Write-Host " not installed, skipping" -ForegroundColor Gray
        } else {
            Write-Host " FAILED: $result" -ForegroundColor Red
        }
        Start-Sleep -Milliseconds 400
    }
}

# ── Verify pm disable-user actually works ──────────────────────────────────
Write-Host "Checking pm disable-user works on this firmware..." -ForegroundColor Cyan
$testPkg = "com.android.wallpaper"
$testResult = adb -s $TV shell "pm disable-user --user 0 $testPkg" 2>&1
if ($testResult -match "SecurityException") {
    Write-Host "[STOP] This firmware refuses pm disable-user (SecurityException)." -ForegroundColor Red
    Write-Host "Debloat is not possible via ADB on this device."
    Write-Host "See docs/TROUBLESHOOTING.md for DNS-blocking fallback."
    exit 1
}
# Re-enable the test package immediately if it worked
adb -s $TV shell "pm enable --user 0 $testPkg" | Out-Null

# ── Take screenshot BEFORE ────────────────────────────────────────────────
Write-Host "Taking 'before' screenshot..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$PSScriptRoot\..\restore_data\shots" | Out-Null
adb -s $TV shell "screencap -p /sdcard/shot_before.png"
adb -s $TV pull "/sdcard/shot_before.png" "$PSScriptRoot\..\restore_data\shots\shot_before.png"
adb -s $TV shell "rm /sdcard/shot_before.png"

# ══════════════════════════════════════════════════════════════════════════
# BATCH 1 – OnePlus/OPPO telemetry and analytics
# ══════════════════════════════════════════════════════════════════════════
Disable-Batch "Batch 1: OnePlus/OPPO analytics & telemetry" @(
    "com.heytap.usercenter"
    "com.heytap.pictorial"
    "com.coloros.datacollection"
    "com.oppo.datacollection"
    "com.oneplus.datacollection"
    "com.coloros.phonemanager"
    "com.coloros.oobe"
    "com.nearme.statistics.rom"
)

# Screenshot after batch 1
adb -s $TV shell "screencap -p /sdcard/shot_b1.png"; adb -s $TV pull "/sdcard/shot_b1.png" "$PSScriptRoot\..\restore_data\shots\shot_batch1.png"; adb -s $TV shell "rm /sdcard/shot_b1.png"
Write-Host "  Screenshot saved: restore_data\shots\shot_batch1.png" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════
# BATCH 2 – OnePlus content/ad services & recommendations
# ══════════════════════════════════════════════════════════════════════════
Disable-Batch "Batch 2: OnePlus content ads & recommendation rows" @(
    "com.heytap.market"
    "com.heytap.browser"
    "com.nearme.gamecenter"
    "com.coloros.filemanager"
    "com.coloros.gallery3d"
    "com.coloros.contentextension"
    "com.coloros.smartsidebar"
    "com.coloros.recommend"
    "com.oppo.quicksearchbox"
)

adb -s $TV shell "screencap -p /sdcard/shot_b2.png"; adb -s $TV pull "/sdcard/shot_b2.png" "$PSScriptRoot\..\restore_data\shots\shot_batch2.png"; adb -s $TV shell "rm /sdcard/shot_b2.png"
Write-Host "  Screenshot saved: restore_data\shots\shot_batch2.png" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════
# BATCH 3 – OnePlus TV-specific bloat (not needed with custom launcher)
# ══════════════════════════════════════════════════════════════════════════
Disable-Batch "Batch 3: OnePlus TV content & partner apps" @(
    "com.oneplus.tv.oobe"
    "com.oneplus.scene"
    "com.oneplus.gallery"
    "com.oneplus.filemanager"
    "tv.danmaku.bili"
    "com.miui.player"
    "com.milink.service"
)

adb -s $TV shell "screencap -p /sdcard/shot_b3.png"; adb -s $TV pull "/sdcard/shot_b3.png" "$PSScriptRoot\..\restore_data\shots\shot_batch3.png"; adb -s $TV shell "rm /sdcard/shot_b3.png"
Write-Host "  Screenshot saved: restore_data\shots\shot_batch3.png" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════
# BATCH 4 – Duplicate share/cast services
# ══════════════════════════════════════════════════════════════════════════
Disable-Batch "Batch 4: Duplicate share/cast services" @(
    "com.coloros.wirelessshare"
    "com.nearme.cloud"
    "com.heytap.cloud"
    "com.oppo.launcher"
)

adb -s $TV shell "screencap -p /sdcard/shot_b4.png"; adb -s $TV pull "/sdcard/shot_b4.png" "$PSScriptRoot\..\restore_data\shots\shot_batch4.png"; adb -s $TV shell "rm /sdcard/shot_b4.png"
Write-Host "  Screenshot saved: restore_data\shots\shot_batch4.png" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════
# Done – reboot and verify
# ══════════════════════════════════════════════════════════════════════════
Write-Host "`n=== Debloat complete. Rebooting TV... ===" -ForegroundColor Green
Write-Host "After reboot, run: adb -s $TV shell 'pm list packages -d'" -ForegroundColor Cyan
Write-Host "Paste the output back to Claude to verify nothing was re-enabled by firmware."
$reboot = Read-Host "Reboot now? [y/N]"
if ($reboot -eq 'y' -or $reboot -eq 'Y') {
    adb -s $TV reboot
    Write-Host "Rebooting... wait 60 seconds then reconnect with 01_connect.ps1"
}
