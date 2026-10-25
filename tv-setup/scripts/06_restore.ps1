# 06_restore.ps1 – Full restore: re-enables everything debloat disabled
# Also restores DNS and can reinstall the stock launcher.

$TV = "192.168.1.128:5555"
$RESTORE_DIR = "$PSScriptRoot\..\restore_data"

# Find the most recent restore script
$restoreFiles = Get-ChildItem "$RESTORE_DIR\restore_*.ps1" | Sort-Object LastWriteTime -Descending
if (-not $restoreFiles) {
    Write-Host "[ERROR] No restore script found in $RESTORE_DIR. Run 02_backup.ps1 first." -ForegroundColor Red
    exit 1
}

$restoreFile = $restoreFiles[0].FullName
Write-Host "Using restore file: $restoreFile" -ForegroundColor Cyan

# Run the generated restore script
& $restoreFile

# Undo Private DNS if it was set
Write-Host "`nUndoing Private DNS (if set)..."
adb -s $TV shell "settings put global private_dns_mode opportunistic"
adb -s $TV shell "settings delete global private_dns_specifier"

# Re-enable the stock launcher
Write-Host "Re-enabling stock OnePlus launcher..."
$stockLaunchers = @(
    "com.oppo.tv.launcher"
    "com.oneplus.tv.launcher"
    "com.android.launcher"
    "com.android.tv.launcher"
)
foreach ($pkg in $stockLaunchers) {
    $check = adb -s $TV shell "pm list packages $pkg" 2>&1
    if ($check -match "package:") {
        Write-Host "  Enabling $pkg ..."
        adb -s $TV shell "pm enable --user 0 $pkg"
    }
}

Write-Host "`n[OK] Restore complete. Rebooting..."
adb -s $TV reboot
