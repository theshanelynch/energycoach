# Energy Coach - Home Assistant Dev Environment

This project provides a local development environment for Home Assistant using Docker and Colima on macOS. It includes a suite of scripts to simplify starting, stopping, backing up, and restoring your instance.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Docker](https://www.docker.com/products/docker-desktop/)
- [Colima](https://github.com/abiosoft/colima)
- [jq](https://stedolan.github.io/jq/) (`brew install jq`)
- qrencode (`brew install qrencode`)

## Getting Started

### 1. Start Colima

For best performance, it's recommended to start Colima with sufficient resources and network address allocation.

```bash
colima stop || true
colima start --cpu 4 --memory 6 --disk 20 --network-address
```

### 2. Start Home Assistant

A single script handles permissions, sets the dynamic internal URL for mobile access, and starts all the Docker containers.

```bash
./start_home_assistant.sh
```

After running, a QR code will be displayed in the terminal to easily open the Home Assistant URL on your phone.

## Management Scripts

| Script | Description |
| :--- | :--- |
| `./start_home_assistant.sh` | Starts the entire Home Assistant environment and generates a QR code for the URL. |
| `./stop_home_assistant.sh` | Stops and removes all related containers gracefully. |
| `scripts/ha_backup.sh` | Creates a compressed backup of the Home Assistant `config`, `media`, and `www` directories. |
| `scripts/ha_get_ip.sh` | A utility script that prints the local network IP (macOS LAN or Colima). |
| `scripts/ha_qr.sh` | Utility script that generates a QR code for the Home Assistant URL. |
| `scripts/ha_restore.sh` | Restores the most recent backup. Asks for confirmation before overwriting data. |
| `scripts/ha_set_internal_url.sh` | Utility script to set the `internal_url` in Home Assistant's configuration. |
| `scripts/ha_token_check.sh` | Utility to verify the long-lived homeassisant token in `secrets/ha_token.txt`. |


