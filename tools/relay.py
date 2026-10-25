#!/usr/bin/env python3
"""
TCP relay: forwards localhost:15555 <-> TV_IP:5555
Run on the host machine (same Wi-Fi as the TV):
    python3 tools/relay.py <tv-ip>
Then in this cloud session use TV_HOST=127.0.0.1 TV_PORT=15555
"""
import socket, threading, sys, time

TV_PORT = 5555
RELAY_PORT = 15555

def pipe(src, dst, label):
    try:
        while True:
            data = src.recv(4096)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        for s in (src, dst):
            try: s.shutdown(socket.SHUT_RDWR)
            except Exception: pass
            try: s.close()
            except Exception: pass

def handle(client, tv_ip):
    tv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        tv.connect((tv_ip, TV_PORT))
    except Exception as e:
        print(f"[relay] Cannot reach TV {tv_ip}:{TV_PORT}: {e}")
        client.close()
        return
    print(f"[relay] connection open")
    t1 = threading.Thread(target=pipe, args=(client, tv, "c->tv"), daemon=True)
    t2 = threading.Thread(target=pipe, args=(tv, client, "tv->c"), daemon=True)
    t1.start(); t2.start()
    t1.join(); t2.join()
    print(f"[relay] connection closed")

def main():
    if len(sys.argv) < 2:
        print(f"Usage: python3 relay.py <tv-ip>")
        sys.exit(1)
    tv_ip = sys.argv[1]
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", RELAY_PORT))
    srv.listen(5)
    print(f"[relay] Listening on 127.0.0.1:{RELAY_PORT} -> {tv_ip}:{TV_PORT}")
    print(f"[relay] Leave this running. In the cloud session set TV_HOST=127.0.0.1 TV_PORT={RELAY_PORT}")
    while True:
        client, addr = srv.accept()
        threading.Thread(target=handle, args=(client, tv_ip), daemon=True).start()

if __name__ == "__main__":
    main()
