# LAN And Tailscale Access

## Names

- **Qwen3.8 vLLM** on TCP 8000
- **Qwen3.8 NInfer** on TCP 8080

## Addresses

```text
LAN:       192.168.1.6
Tailscale: 100.73.145.5
MagicDNS:  dodhya-rtx
```

## Base URLs

| Engine | LAN | Tailscale |
| --- | --- | --- |
| vLLM | `http://192.168.1.6:8000/v1` | `http://100.73.145.5:8000/v1` |
| NInfer | `http://192.168.1.6:8080/v1` | `http://100.73.145.5:8080/v1` |

Each engine has a distinct bearer key in its ignored local config file. Requests
to `/v1/*` without the correct key return HTTP 401.

## Local Configuration

```bash
# config.env
HOST=0.0.0.0
API_KEY=<generated secret>

# config.ninfer.env
NINFER_HOST=0.0.0.0
NINFER_API_KEY=<different generated secret>
```

Generate replacement keys with:

```bash
openssl rand -hex 32
```

Restart the corresponding server after rotating a key.

## UFW Rules

UFW is active on the tested machine. Run these commands locally on the RTX host
with sudo to allow only the home LAN and Tailscale interface:

```bash
sudo ufw allow in on tailscale0 to any port 8000 proto tcp comment 'Qwen3.8 vLLM via Tailscale'
sudo ufw allow in on tailscale0 to any port 8080 proto tcp comment 'Qwen3.8 NInfer via Tailscale'
sudo ufw allow from 192.168.1.0/24 to any port 8000 proto tcp comment 'Qwen3.8 vLLM via LAN'
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp comment 'Qwen3.8 NInfer via LAN'
sudo ufw status numbered
```

Review existing rules first. If broader existing allow rules expose these ports,
remove or narrow those rules. Do not add unrestricted `allow 8000` or
`allow 8080` rules.

## Verification

With an engine running, test from another LAN or Tailscale device:

```bash
curl -i http://100.73.145.5:8080/v1/models
curl -i -H 'Authorization: Bearer YOUR_KEY' \
  http://100.73.145.5:8080/v1/models
```

Expected status codes are 401 without a key and 200 with the correct key.

The NInfer `/health` endpoint is intentionally unauthenticated upstream. Treat
it only as a liveness signal; use authenticated `/v1/models` for readiness and
model identity.

## Security Notes

- Never commit either local config file.
- Do not expose these ports through router port forwarding.
- Tailscale traffic is encrypted, but bearer authentication remains enabled.
- LAN HTTP is not encrypted. The bearer key protects authorization but can be
  observed by a compromised LAN device. For stronger LAN security, use
  Tailscale only or place an HTTPS reverse proxy in front of the APIs.
- Do not run vLLM and NInfer simultaneously; each expects exclusive GPU use.
