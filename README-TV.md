# OnePlus TV Y Series – Debloat & Custom Launcher

Apple TV-style home screen for your OnePlus TV Y Series.

## Quick start

### 1. Connect
Run the relay on your computer (same Wi-Fi as the TV):
```bash
python3 tools/relay.py 192.168.1.128
```
Leave that terminal open. The cloud session connects through it.

### 2. Build & install the launcher
```bash
# First time only: generate Gradle wrapper
cd launcher && gradle wrapper && cd ..

./build-and-install.sh
```

### 3. Restore everything
```bash
./backup/restore.sh
```

---

## Changing dock apps / columns

Edit `launcher/app/src/main/res/values/config.xml`:

```xml
<integer name="columns">5</integer>

<string-array name="dock_apps">
    <item>com.google.android.youtube.tv</item>
    <item>com.netflix.ninja</item>
    <!-- add/remove packages here -->
</string-array>
```

Then rebuild: `./build-and-install.sh`

---

## Re-enabling a disabled app

```bash
python3 tools/tv.py "pm enable --user 0 com.example.package"
```

---

## Ad-blocking DNS (optional)

Enable:
```bash
python3 tools/tv.py "settings put global private_dns_specifier dns.adguard-dns.com"
python3 tools/tv.py "settings put global private_dns_mode hostname"
```
Disable:
```bash
python3 tools/tv.py "settings put global private_dns_mode opportunistic"
```
Note: does **not** block YouTube ads. Goes around Pi-hole / router DNS if you have one.

---

## Close ADB when done

1. TV → Settings → Device Preferences → Developer options → turn off USB debugging & Network/ADB debugging
2. Verify the port is closed (run on your computer):
   ```
   python3 tools/adb-closed.py 192.168.1.128
   ```
   You want: `CLOSED – port 5555 ... refused the connection`

---

## Troubleshooting

See `docs/TROUBLESHOOTING.md`.
