# OnePlus TV Y Series – Debloat & Custom Launcher

**TV model**: OnePlus TV Y series · **IP**: 192.168.1.128

---

## What was done

| Step | Description |
|------|-------------|
| Backup | Full package list, getprop, settings → `restore_data/` |
| Debloat | OnePlus/OPPO analytics, content ads, duplicate services disabled |
| Launcher | Custom Apple TV-style home screen installed |

**Kept**: YouTube, Netflix, Prime Video, Hotstar, Apple TV, Google Assistant, Chromecast, OTA updates

---

## How to change the dock order or add/remove apps

Edit `launcher/app/src/main/res/values/config.xml`:

```xml
<string-array name="dock_apps">
    <item>com.google.android.youtube.tv</item>   <!-- YouTube -->
    <item>com.netflix.ninja</item>               <!-- Netflix -->
    <item>com.amazon.amazonvideo.livingroom</item><!-- Prime Video -->
    <item>in.startv.hotstar</item>               <!-- Hotstar -->
    <item>com.apple.atve.androidtv.appletv</item><!-- Apple TV -->
</string-array>
```

Then re-run `tv-setup\scripts\05_build_install.ps1`.

---

## How to re-enable any app

Open PowerShell and run:
```powershell
adb -s 192.168.1.128:5555 shell "pm enable --user 0 <package.name>"
```

Or run `tv-setup\scripts\06_restore.ps1` to re-enable everything at once.

---

## How to find a package name

```powershell
adb -s 192.168.1.128:5555 shell "pm list packages | findstr <partial name>"
```

---

## Set ad-blocking DNS (optional)

OnePlus TV Y series runs Android 11+, so Private DNS works:

```powershell
# Enable
adb -s 192.168.1.128:5555 shell "settings put global private_dns_specifier dns.adguard-dns.com"
adb -s 192.168.1.128:5555 shell "settings put global private_dns_mode hostname"

# Undo
adb -s 192.168.1.128:5555 shell "settings put global private_dns_mode opportunistic"
```

> **Note**: This does NOT block YouTube ads. If your router uses Pi-hole, AdGuard Home, or a VPN
> with domain lists, **don't enable this** — Private DNS bypasses the router's DNS, so those rules
> stop applying to the TV. Use the router's filtering instead.

---

## Close ADB when done

```powershell
adb -s 192.168.1.128:5555 tcpip 5554   # not strictly needed
adb disconnect 192.168.1.128:5555
```

Then on the TV: **Settings → Developer options → turn off USB debugging and Network/ADB debugging → Revoke USB debugging authorisations → Reboot**.

---

## Restore everything

```powershell
.\tv-setup\scripts\06_restore.ps1
```

This re-enables all disabled packages and reinstalls the stock launcher as Home.
