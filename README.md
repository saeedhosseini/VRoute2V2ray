# vRoute → v2Ray Gateway

## Overview

This project turns a **commercial OpenVPN (vRoute) account** into a **local v2Ray / VMess gateway** for LAN or small teams.

Instead of connecting every device directly to the OpenVPN provider (which is often limited or sensitive to multiple devices), this setup:

- Connects **once** to vRoute using OpenVPN
- Exposes a **local v2Ray (VMess) endpoint**
- Allows controlled access for internal devices via v2Ray clients (e.g. v2rayNG)

All management (VPN selection, credentials, ports, start/stop) is done via a **CMD-based interactive menu**.

---

## Architecture

```
[ Devices / Clients ]
        |
     v2Ray (VMess)
        |
[ Local Gateway Machine ]
        |
     OpenVPN Client
        |
     vRoute Servers
```

---

## Features

- OpenVPN client inside Docker (vRoute compatible)
- Xray (v2Ray core) for VMess connections
- Interactive **CMD menu** (no PowerShell required)
- Switch OpenVPN servers:
  - UDP / TCP
  - Server index **2 → 13**
- Dynamic configuration:
  - Host IP
  - Port (via `.env`)
  - OpenVPN username & password
- Auto-generate:
  - `client.json`
  - `vmess://` links (ready for v2rayNG)
- Start / Stop / Restart gateway safely
- Designed for **corporate / restricted Windows environments**

---

## Project Structure

```
dockers/
├─ docker-compose.yml
├─ .env
├─ settings.ini
├─ runner.bat
├─ menu.bat
│
├─ ovpn/
│  ├─ ACTIVE.ovpn
│  ├─ auth.txt
│  ├─ VS2_UDP.ovpn
│  ├─ VS2_TCP.ovpn
│  └─ ... VS13_*.ovpn
│
└─ xray/
   └─ config.json
```

---

## Requirements

- Windows 10 / 11
- Docker Desktop
- CMD access (Run as Administrator)
- OpenVPN `.ovpn` configs from vRoute

PowerShell is **not required**.

---

## Usage

### Start the menu

```cmd
cd C:\Users\s.hosseini\dockers
runner.bat
```

### Menu capabilities

- Configure host IP, port, OpenVPN credentials
- Select OpenVPN server (UDP/TCP, 2–13)
- Start / stop / restart the gateway
- View Docker status and logs
- Generate v2Ray client configurations

---

## Why This Exists

Many VPN providers (including vRoute):

- Limit concurrent devices
- Detect multiple direct connections
- Become unstable in corporate networks

This gateway approach:

- Uses **one stable OpenVPN connection**
- Distributes access internally via v2Ray
- Gives full control over how the VPN is used
- Reduces risk of account suspension

---

## Security Notes

- OpenVPN credentials are stored in `settings.ini`
- `auth.txt` is generated **only when starting** the gateway
- v2Ray runs only on the configured local port
- Firewall rules should be applied to restrict LAN access

---

## Intended Use

- Small teams
- Corporate environments
- Development offices
- Controlled shared VPN access

This project is **not intended for public redistribution or abuse of VPN services**.

---

## Status

- Core gateway: ✅ Stable
- Server switching: ✅
- Dynamic port & config: ✅
- User management: ⏳ Planned
