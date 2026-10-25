# Troubleshooting

## Screenshots come out empty / 0 bytes
Live TV, HDMI inputs and DRM-protected apps (Netflix) return an empty buffer.
Check the current activity instead:
```
dumpsys activity activities | grep topResumedActivity
```

## screencap returns the same frame repeatedly
```
dumpsys window | grep mCurrentFocus
adb shell am force-stop <package>
# then capture again
```

## Screen looks enlarged/clipped after install
Check display overrides before editing the launcher:
```
wm size       # shows physical + override
wm density    # shows physical + override
settings get secure display_density_forced
```
Put them back with `wm size reset` and `wm density reset` if wrong.

## pm disable-user refused for every package (SecurityException)
Some firmware (Fire OS 5) refuses all `pm disable-user` calls. Check:
```
pm list packages -d
```
If nothing is disabled, fall back to:
- Privacy toggles in the TV's own settings
- DNS-level blocking (AdGuard DNS)
See docs/TROUBLESHOOTING.md#dns-blocking

## Factory / AT menu accidentally opened (CVTE boards)
Opening `com.cvte.tv.hkcfac` or `com.cvte.tv.fac.menu` on a Haier/CVTE board flips a
factory-mode flag. Symptoms: Input key stops working, next boot disables Play Services.

Recovery:
1. Open the factory app again (if you can)
2. Find the "Normal mode" or "User mode" toggle and set it
3. Reboot

If you can't get back in: `adb shell am start -n com.cvte.tv.hkcfac/.MainActivity`
then navigate to Exit Factory Mode.

## Google TV: setupwraith keeps taking over Home
Before disabling setupwraith, check saved Wi-Fi networks:
```
dumpsys wifi | grep -o 'cname=[^ ]*'
```
If a network name appears, forget and re-join it from Settings first — Android deletes
that network when setupwraith is disabled.

## ADB closed check (macOS)
Don't trust `nc` on macOS; Local Network privacy can block it and return "No route
to host" even when the port is open. Use `tools/adb-closed.py <ip>` instead.

## Key repeat stops working after launcher install
On TCL G09 (Google TV 12), enabling the key-filtering accessibility service drops
key repeats to one step per press. You can:
1. Leave the helper off and remap buttons manually
2. Accept one-step volume (press repeatedly)
3. Use a different TV remote app

## DNS blocking (optional)
Set private DNS on Android 9+:
```
settings put global private_dns_specifier dns.adguard-dns.com
settings put global private_dns_mode hostname
```
Undo:
```
settings put global private_dns_mode opportunistic
```
Note: does NOT block YouTube ads. Goes around Pi-hole/AdGuard Home if your router
already filters DNS — use router-level blocking there instead.
