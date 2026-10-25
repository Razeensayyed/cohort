# relay.py – local network relay for cloud ADB sessions

Since this session runs in a cloud container it cannot directly reach your TV's
local IP. `relay.py` bridges the gap by running on **your machine** (same Wi-Fi as
the TV) and forwarding a local TCP port to the TV.

## Steps

1. On your computer, open a terminal and run:
   ```
   python3 tools/relay.py <TV-IP>
   ```
   Leave it running the whole session.

2. In this cloud session, all `tv.py` calls use the relay automatically:
   ```
   TV_HOST=127.0.0.1 TV_PORT=15555
   ```
   (already the defaults in tv.py)

## What it does

Listens on `127.0.0.1:15555` and forwards every TCP connection to `<TV-IP>:5555`.
The cloud session connects to the relay; the relay connects to the TV.
