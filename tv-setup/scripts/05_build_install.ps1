# 05_build_install.ps1
# Builds the launcher APK with Gradle and installs it on the OnePlus TV Y series.
# Prerequisites:
#   - Java 17 JDK installed and JAVA_HOME set (or java.exe on PATH)
#   - ADB connected (run 01_connect.ps1 first)
#   - Outfit font files in launcher\app\src\main\res\font\
#     (see launcher\app\src\main\res\font\outfit_placeholder.md)

$TV       = "192.168.1.128:5555"
$REPO     = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)  # repo root
$LAUNCHER = Join-Path $REPO "launcher"
$APK      = Join-Path $LAUNCHER "app\build\outputs\apk\debug\app-debug.apk"

Set-Location $LAUNCHER

# ── Pre-flight checks ──────────────────────────────────────────────────────
Write-Host "Pre-flight checks..." -ForegroundColor Cyan

# Java
$javaVersion = java -version 2>&1 | Select-String "version"
if (-not $javaVersion) {
    Write-Host "[ERROR] Java not found. Install JDK 17 from https://adoptium.net" -ForegroundColor Red
    exit 1
}
Write-Host "  Java: $javaVersion"

# Outfit fonts
$fonts = @("outfit_thin.ttf","outfit_light.ttf","outfit_regular.ttf")
$fontDir = Join-Path $LAUNCHER "app\src\main\res\font"
$missing = $fonts | Where-Object { -not (Test-Path (Join-Path $fontDir $_)) }
if ($missing) {
    Write-Host "[ERROR] Missing font files in $fontDir :" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host "See launcher\app\src\main\res\font\outfit_placeholder.md for download instructions." -ForegroundColor Yellow
    exit 1
}
Write-Host "  Fonts: OK"

# ADB device
$devices = adb devices
if ($devices -notmatch $TV.Replace(":","\:")) {
    Write-Host "[ERROR] TV not connected. Run 01_connect.ps1 first." -ForegroundColor Red
    exit 1
}
Write-Host "  ADB: OK"

# SDK level
$sdk = adb -s $TV shell "getprop ro.build.version.sdk"
$sdk = $sdk.Trim()
Write-Host "  TV SDK level: $sdk"
if ([int]$sdk -lt 26) {
    Write-Host "[ERROR] TV SDK $sdk is below minSdk 26 (Android 8.0). Launcher cannot be installed." -ForegroundColor Red
    exit 1
}

# ── Build ──────────────────────────────────────────────────────────────────
Write-Host "`nBuilding launcher APK..." -ForegroundColor Cyan
.\gradlew.bat assembleDebug
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed. Check Gradle output above." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Build succeeded." -ForegroundColor Green

# ── Sideload check ─────────────────────────────────────────────────────────
Write-Host "`nChecking if the TV accepts sideloads..." -ForegroundColor Cyan
# Push a minimal test and check for INSTALL_FAILED_VERIFICATION_FAILURE
$testResult = adb -s $TV install -r $APK 2>&1
if ($testResult -match "INSTALL_FAILED_VERIFICATION_FAILURE") {
    Write-Host "[STOP] TV rejects all sideloads (INSTALL_FAILED_VERIFICATION_FAILURE)." -ForegroundColor Red
    Write-Host "The launcher half is not possible on this device. Debloat only." -ForegroundColor Yellow
    exit 1
}

# ── Install (Android 14 safe: push + pm install) ───────────────────────────
Write-Host "Pushing APK..." -ForegroundColor Cyan
adb -s $TV push $APK /sdcard/launcher.apk

Write-Host "Installing (watch TV screen for confirmation prompt)..." -ForegroundColor Yellow
$install = adb -s $TV shell "pm install -r /sdcard/launcher.apk" 2>&1
Write-Host $install
adb -s $TV shell "rm /sdcard/launcher.apk"

if ($install -notmatch "Success") {
    Write-Host "[ERROR] Install failed. See message above." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Launcher installed." -ForegroundColor Green

# ── Check for competing HOME handlers ────────────────────────────────────
Write-Host "`nChecking HOME intent handlers..." -ForegroundColor Cyan
$homeHandlers = adb -s $TV shell "cmd package query-activities -a android.intent.action.MAIN -c android.intent.category.HOME"
Write-Host $homeHandlers

# ── Check for Google TV setupwraith ───────────────────────────────────────
if ($homeHandlers -match "setupwraith") {
    Write-Host "`n[WARN] Google TV setupwraith is present." -ForegroundColor Yellow
    Write-Host "Checking if Wi-Fi network is owned by setupwraith..."
    $wifi = adb -s $TV shell "dumpsys wifi | grep -o 'cname=[^ ]*'" 2>&1
    Write-Host "  $wifi"
    Write-Host "If setupwraith owns your Wi-Fi network, forget and rejoin in Settings BEFORE we disable it."
    $proceed = Read-Host "Ready to set new launcher as Home? [y/N]"
    if ($proceed -ne 'y' -and $proceed -ne 'Y') { exit 0 }
}

# ── Set as default Home ────────────────────────────────────────────────────
Write-Host "`nSetting launcher as default Home..." -ForegroundColor Cyan
adb -s $TV shell "cmd package set-home-activity com.oneplustvlauncher/.MainActivity"

# ── Verify ─────────────────────────────────────────────────────────────────
Start-Sleep -Seconds 2
$focused = adb -s $TV shell "dumpsys activity activities | grep mFocusedApp"
Write-Host "Focused app: $focused"
if ($focused -match "oneplustvlauncher") {
    Write-Host "[OK] New launcher is the focused app." -ForegroundColor Green
} else {
    Write-Host "[NOTE] Launcher set but not yet focused. Press Home on the remote." -ForegroundColor Yellow
}

# ── Disable stock launcher ─────────────────────────────────────────────────
$disableStock = Read-Host "`nDisable stock OnePlus launcher now? [y/N]"
if ($disableStock -eq 'y' -or $disableStock -eq 'Y') {
    $stockLaunchers = @(
        "com.oppo.tv.launcher"
        "com.oneplus.tv.launcher"
        "com.android.tv.launcher"
    )
    foreach ($pkg in $stockLaunchers) {
        $check = adb -s $TV shell "pm list packages $pkg" 2>&1
        if ($check -match "package:") {
            Write-Host "  Disabling $pkg ..."
            adb -s $TV shell "pm disable-user --user 0 $pkg"
        }
    }
}

# ── Reboot and screenshot ──────────────────────────────────────────────────
Write-Host "`nRebooting TV..." -ForegroundColor Cyan
adb -s $TV reboot
Write-Host "Wait 60 seconds, then reconnect and take a screenshot:"
Write-Host "  adb -s $TV shell screencap -p /sdcard/after.png"
Write-Host "  adb -s $TV pull /sdcard/after.png ."

Write-Host "`nDone! Check the README for how to change the dock order or re-enable apps." -ForegroundColor Green
