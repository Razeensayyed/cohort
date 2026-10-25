#!/usr/bin/env python3
"""
Verify that port 5555 on the TV is closed (connection refused, not just filtered).
Usage: python3 tools/adb-closed.py <tv-ip>
"""
import socket, sys

def check(ip, port=5555):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(5)
    try:
        s.connect((ip, port))
        s.close()
        print(f"OPEN – port {port} on {ip} is still accepting connections. ADB is NOT closed.")
        sys.exit(1)
    except ConnectionRefusedError:
        print(f"CLOSED – port {port} on {ip} refused the connection. ADB is safely closed.")
        sys.exit(0)
    except OSError as e:
        print(f"FILTERED/UNREACHABLE – {e}. Cannot confirm closed (macOS Local Network block?)")
        sys.exit(2)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: adb-closed.py <tv-ip>")
        sys.exit(1)
    check(sys.argv[1])
