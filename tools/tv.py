#!/usr/bin/env python3
"""
tv.py – thin wrapper around adb-shell for the AndroidTV debloat project.

Usage:
    tv.py 'shell command'
    tv.py --screenshot shots/out.png [KEYCODE ...]
    tv.py --push local/file /remote/path

Environment:
    TV_HOST   (default 127.0.0.1)
    TV_PORT   (default 15555)
"""
import os, sys, time, base64, hashlib, tempfile, pathlib, argparse

TV_HOST = os.environ.get("TV_HOST", "127.0.0.1")
TV_PORT = int(os.environ.get("TV_PORT", "15555"))

# ── adb-shell connection ────────────────────────────────────────────────────
try:
    from adb_shell.adb_device import AdbDeviceTcp
    from adb_shell.auth.sign_pythonrsa import PythonRSASigner
    from adb_shell.auth.keygen import keygen
except ImportError:
    sys.exit("adb-shell not installed: pip3 install 'adb-shell==0.4.0'")

KEY_DIR = pathlib.Path.home() / ".android"
PRIV_KEY = KEY_DIR / "adbkey"
PUB_KEY  = KEY_DIR / "adbkey.pub"

def get_signer():
    KEY_DIR.mkdir(exist_ok=True)
    if not PRIV_KEY.exists():
        keygen(str(PRIV_KEY))
    with open(PRIV_KEY) as f:
        priv = f.read()
    with open(PUB_KEY) as f:
        pub = f.read()
    return PythonRSASigner(pub, priv)

def connect():
    dev = AdbDeviceTcp(TV_HOST, TV_PORT, default_transport_timeout_s=30)
    dev.connect(rsa_keys=[get_signer()], auth_timeout_s=20)
    return dev

# ── helpers ─────────────────────────────────────────────────────────────────
KEYCODES = {
    "DPAD_UP": 19, "DPAD_DOWN": 20, "DPAD_LEFT": 21, "DPAD_RIGHT": 22,
    "DPAD_CENTER": 23, "ENTER": 66, "BACK": 4, "HOME": 3, "MENU": 82,
    "VOLUME_UP": 24, "VOLUME_DOWN": 25, "MUTE": 164,
    "MEDIA_PLAY_PAUSE": 85, "MEDIA_STOP": 86, "MEDIA_NEXT": 87,
    "MEDIA_PREVIOUS": 88, "POWER": 26,
}

def inject_key(dev, key):
    code = KEYCODES.get(key.upper(), key)
    dev.shell(f"input keyevent {code}")

def screenshot(dev, out_path):
    pathlib.Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    # pull via base64 to avoid binary pipe issues
    b64 = dev.shell("screencap -p | base64 -w 0", timeout_s=30)
    if not b64 or not b64.strip():
        print("ERROR: screenshot is empty (DRM/protected surface?)", file=sys.stderr)
        sys.exit(1)
    raw = base64.b64decode(b64.strip())
    if len(raw) < 100:
        print(f"ERROR: screenshot too small ({len(raw)} bytes)", file=sys.stderr)
        sys.exit(1)
    with open(out_path, "wb") as f:
        f.write(raw)
    print(f"screenshot saved: {out_path} ({len(raw)} bytes)")

def push_file(dev, local, remote):
    """Push a file via base64 chunks (avoids hangs on larger files)."""
    CHUNK = 32768
    with open(local, "rb") as f:
        data = f.read()
    local_md5 = hashlib.md5(data).hexdigest()
    # write in chunks
    dev.shell(f"rm -f {remote}.tmp")
    for i in range(0, len(data), CHUNK):
        chunk_b64 = base64.b64encode(data[i:i+CHUNK]).decode()
        dev.shell(f"echo '{chunk_b64}' | base64 -d >> {remote}.tmp")
    dev.shell(f"mv {remote}.tmp {remote}")
    remote_md5 = dev.shell(f"md5sum {remote}").split()[0].strip()
    if local_md5 != remote_md5:
        print(f"ERROR: md5 mismatch local={local_md5} remote={remote_md5}", file=sys.stderr)
        sys.exit(1)
    print(f"pushed {local} -> {remote} md5={local_md5} OK")

# ── main ─────────────────────────────────────────────────────────────────────
def main():
    p = argparse.ArgumentParser()
    p.add_argument("--screenshot", metavar="OUT.png")
    p.add_argument("--push", nargs=2, metavar=("LOCAL", "REMOTE"))
    p.add_argument("args", nargs="*")
    opts = p.parse_args()

    dev = connect()

    if opts.screenshot:
        for key in opts.args:
            inject_key(dev, key)
            time.sleep(0.5)
        screenshot(dev, opts.screenshot)
    elif opts.push:
        push_file(dev, opts.push[0], opts.push[1])
    elif opts.args:
        cmd = " ".join(opts.args)
        out = dev.shell(cmd, timeout_s=60)
        print(out, end="" if out.endswith("\n") else "\n")
    else:
        p.print_help()

if __name__ == "__main__":
    main()
