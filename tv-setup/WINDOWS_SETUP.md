# OnePlus TV Y Series – Windows Setup Guide

## Step 1 · Install ADB on Windows

1. Go to https://developer.android.com/tools/releases/platform-tools
2. Click **"Download SDK Platform-Tools for Windows"**
3. Extract the ZIP to `C:\platform-tools\`
4. Open **Start → search "Environment Variables" → Edit the system environment variables → Environment Variables → Path → Edit → New** and add `C:\platform-tools`
5. Open a **new** PowerShell window and verify:
   ```
   adb version
   ```
   You should see `Android Debug Bridge version 1.x.x`.

## Step 2 · Enable ADB on the TV

On the TV remote:
1. **Settings → Device Preferences → About → Build** — press **OK** on "Build" **7 times**
2. Go back → **Developer options** → turn on **USB debugging** and **Network/ADB debugging**

## Step 3 · Run these scripts

Open PowerShell **as Administrator**, `cd` to the `tv-setup\scripts` folder in this repo, and run the scripts in order:

| Script | What it does |
|--------|-------------|
| `01_connect.ps1` | Connects ADB to your TV and confirms the connection |
| `02_backup.ps1` | Saves full package list, settings, and getprop to `restore_data\` |
| `03_list_packages.ps1` | Dumps all packages — **paste the output** back to Claude |
| `04_debloat.ps1` | Disables bloatware in small batches with confirmations |
| `05_build_install.ps1` | Builds the launcher APK and installs it on the TV |
| `06_restore.ps1` | Full restore — re-enables everything `04_debloat.ps1` disabled |

> **TV model**: OnePlus TV Y series  
> **TV IP**: 192.168.1.128  
> **ADB port**: 5555

## Important warnings

- Nothing is plugged into the USB ports, so you're safe to leave ADB on during the session.
- When you're done, the scripts will close ADB and instruct you to turn off USB/Network debugging in Settings.
- OTA updates are **kept** on. OnePlus updates may re-enable some packages after an update — run `04_debloat.ps1` again if that happens.
