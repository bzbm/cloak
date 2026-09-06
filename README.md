# cloak

a tunnel that isn't there.

VLESS + WebSocket + TLS, self-hosted on Azure, to get around a Sophos captive portal that was blocking everything else.

---

## the problem

Uni network runs Sophos with proper DPI, not just port blocking. Tried the obvious stuff first:

- WireGuard — nope, all UDP gets dropped, doesn't matter which port
- Shadowsocks / Outline — connects for a second then gets reset, Sophos fingerprints the protocol
- Cloudflare WARP — worked for a bit, then got explicitly blocked once the admin noticed
- Direct IP connections — `curl -I https://<ip>` just resets. Sophos only lets through HTTPS to real domains

So the actual constraint: traffic has to *look* like normal HTTPS to a real site with a real cert. Anything that smells like a proxy gets killed.

## why this setup

VLESS on WebSocket over TLS, port 443, pointed at a real DuckDNS domain with an actual Let's Encrypt cert. No fingerprint, no weirdness — just looks like a browser talking to a website.

First tried VLESS+Reality (mimics TLS to google.com) but the traffic pattern wasn't convincing enough and my key/shortId setup was off anyway. Scrapped it and went with a real domain + real cert instead of faking one. (named the website honoring our glorious IT department : fuckuccit.duckdns.org)

## setup

```
client (Mac/phone) --VLESS/WS/TLS:443--> Sophos --passes as HTTPS--> Azure VM (Xray, /vpn path) --> internet
```

- Server: Azure B1ls (1 vCPU, 0.5GB), Ubuntu 22.04, Xray as a systemd service
- Domain: DuckDNS, cert: Let's Encrypt via Certbot
- Client: V2RayXS on Mac, v2rayNG on Android

## things that broke along the way

- **Config wouldn't load, exit code 23** — turned out I had two JSON objects stuck together in config.json (old Reality config + new one, didn't fully clear the file before pasting). Overwrote clean with `tee` instead of editing in nano.
- **Xray ran fine manually but died as a service** — it runs as `nobody`, and that user couldn't read the Let's Encrypt certs (they're `700` by default). Fixed with `chmod 755` on the cert dirs and `644` on the `.pem` files.
- **SSH kept refusing** — forgot the `-i` flag for the key file. Rookie mistake, wasted more time than I'd like to admit.

## result

Got it to ~180mbps on a locked-down LAN. Not the full 800mbps the connection can do, but the B1ls VM is a shared vCPU so that's the ceiling. Fine for browsing, video, everything normal.

Doesn't work: Discord VC, Roblox, anything UDP-based — Sophos kills all UDP regardless, and this tunnel is TCP-only. Could theoretically wrap UDP in TCP but the latency hit isn't worth it.
