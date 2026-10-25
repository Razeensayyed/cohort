# Remote / Tailscale access

If the TV is on a different network (e.g. another home), connect it to Tailscale
and give the session its Tailscale IP instead:

```
TV_HOST=<tailscale-ip> TV_PORT=5555 python3 tools/tv.py 'echo connected'
```

No relay needed when using Tailscale — just make sure the TV's Tailscale node is online.
