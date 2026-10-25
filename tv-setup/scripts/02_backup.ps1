# 02_backup.ps1 – Full backup before any changes
# Saves to tv-setup\restore_data\

$TV = "192.168.1.128:5555"
$BACKUP_DIR = "$PSScriptRoot\..\restore_data"

New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
$TS = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "Backing up to $BACKUP_DIR ..." -ForegroundColor Cyan

# Full package list
Write-Host "  [1/4] All packages..."
adb -s $TV shell "pm list packages -f" | Out-File "$BACKUP_DIR\packages_all_$TS.txt"

# Disabled packages
Write-Host "  [2/4] Disabled packages..."
adb -s $TV shell "pm list packages -d" | Out-File "$BACKUP_DIR\packages_disabled_$TS.txt"

# getprop
Write-Host "  [3/4] System properties..."
adb -s $TV shell "getprop" | Out-File "$BACKUP_DIR\getprop_$TS.txt"

# Settings (global, secure, system)
Write-Host "  [4/4] Settings..."
$settings = @("global", "secure", "system")
foreach ($ns in $settings) {
    adb -s $TV shell "settings list $ns" | Out-File "$BACKUP_DIR\settings_${ns}_$TS.txt"
}

Write-Host "`n[OK] Backup complete." -ForegroundColor Green
Write-Host "Files saved to: $BACKUP_DIR"

# Also write restore script
$restoreScript = @"
# restore_$TS.ps1 – Undo everything 04_debloat.ps1 does
# Generated automatically at backup time
# Edit the package list below to match what 04_debloat.ps1 actually disabled.

`$TV = "192.168.1.128:5555"

`$PACKAGES = @(
    # Filled in by 04_debloat.ps1 as it disables each package
)

foreach (`$pkg in `$PACKAGES) {
    Write-Host "Re-enabling `$pkg ..."
    adb -s `$TV shell "pm enable --user 0 `$pkg"
    Start-Sleep -Milliseconds 300
}

Write-Host "Restore complete. Reboot the TV: adb -s `$TV reboot"
"@

$restoreScript | Out-File "$BACKUP_DIR\restore_$TS.ps1"
Write-Host "Restore script template: $BACKUP_DIR\restore_$TS.ps1"
Write-Host "(It will be auto-populated as debloat runs.)"
