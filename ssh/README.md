# ⚓ SSH Setup — *Castillo de Jagua*
> Setting sail with secure, key-based SSH and Wake-on-LAN for a Proxmox homelab.

---

## 📋 Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Generate an SSH Key](#step-1--generate-an-ssh-key)
- [Step 2 — Upload Your Public Key to GitHub](#step-2--upload-your-public-key-to-github)
- [Step 3 — Import Your Key to the Server](#step-3--import-your-key-to-the-server)
- [Step 4 — Disable Password Authentication](#step-4--disable-password-authentication)
- [Step 5 — Clone This Repo and Set Up the Wake-on-LAN Script](#step-5--clone-this-repo-and-set-up-the-wake-on-lan-script)
- [Step 6 — Configure SSH](#step-6--configure-ssh)
- [Errors & Fixes](#errors--fixes)

---

## Overview

This repo documents the SSH setup for a Proxmox homelab server. The goal is:

- 🔑 **Key-based authentication only** — no passwords
- 🌊 **Wake-on-LAN via ProxyCommand** — automatically wake the server before connecting
- 🏴‍☠️ **Named SSH host** — `ssh castillo-de-jagua` instead of `ssh root@x.x.x.x`

---

## Prerequisites

On your **laptop**, make sure you have:
- `wakeonlan` installed
  ```bash
  # Debian/Ubuntu/Zorin
  sudo apt install wakeonlan

  # Arch/EndeavourOS/Manjaro
  sudo pacman -S wakeonlan

  # macOS
  brew install wakeonlan
  ```
- `netcat` (`nc`) installed — usually pre-installed on most distros
- A GitHub account

On your **server**:
- Proxmox VE installed with a static IP
- Wake-on-LAN enabled in BIOS/UEFI
- Access to the Proxmox web UI shell (`https://<server-ip>:8006`)

---

## Step 1 — Generate an SSH Key

On your **laptop**, run:

```bash
ssh-keygen -t ed25519 -C "your-laptop-name"
```

- When prompted for a file location, press **Enter** to accept the default (`~/.ssh/id_ed25519`)
- Set a **passphrase** when prompted — this protects your key if your laptop is ever stolen

> 💡 Already have a key? Check first with `ls ~/.ssh/` — if `id_ed25519` exists, skip this step.

---

## Step 2 — Upload Your Public Key to GitHub

1. Copy your public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Go to **GitHub → Settings → SSH and GPG keys → New SSH key**
3. Name it after your **laptop** (e.g. `dell-xps`, `macbook-pro`)
4. Paste the key and save

---

## Step 3 — Import Your Key to the Server

In the **Proxmox web UI shell** (`https://<server-ip>:8006` → Shell), run:

```bash
# Install ssh-import-id if not present
apt install ssh-import-id

# Import your public key from GitHub
ssh-import-id gh:your-github-username
```

This pulls your public key from `github.com/your-github-username.keys` and adds it to `/root/.ssh/authorized_keys`.

---

## Step 4 — Disable Password Authentication

> ⚠️ **Before doing this**, open a **new terminal window** and confirm you can SSH in with your key successfully. Locking yourself out requires fixing via the web UI shell.

In the Proxmox shell:

```bash
nano /etc/ssh/sshd_config
```

Find and set:
```
PasswordAuthentication no
```

Then restart SSH:
```bash
systemctl restart sshd
```

---

## Step 5 — Clone This Repo and Set Up the Wake-on-LAN Script

On your **laptop**:

```bash
# Clone the repo
git clone https://github.com/your-github-username/your-repo-name.git
cd your-repo-name

# Copy the script to your .ssh directory
cp ssh/wake-proxy.sh ~/.ssh/wake-proxy.sh

# Make it executable
chmod +x ~/.ssh/wake-proxy.sh
```

Open the script and verify the MAC address is correct for your server:
```bash
nano ~/.ssh/wake-proxy.sh
```

The relevant line:
```bash
MAC="a8:a1:59:4b:f2:23"  # Your server's MAC address
```

### What the script does

When you run `ssh castillo-de-jagua`, this script:
1. Checks if the server is already reachable
2. If not, sends a Wake-on-LAN magic packet to the server's MAC address
3. Retries the connection every 3 seconds for up to 45 seconds
4. Connects once the server responds

---

## Step 6 — Configure SSH

Copy the config from this repo to your SSH directory:

```bash
cp ssh/config ~/.ssh/config
```

Then edit it with your actual values:

```bash
nano ~/.ssh/config
```

The config block looks like this:

```ssh-config
# ---- Naval Fort ----
Host castillo-de-jagua
    HostName XXX.XXX.XXX.XXX        # Your server's static IP
    User root
    ProxyCommand /home/<your-user>/.ssh/wake-proxy.sh %h %p
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Replace:
- `XXX.XXX.XXX.XXX` → your server's static IP
- `<your-user>` → your laptop's username (e.g. `/home/captain-kenway/`)

Once saved, connect with:
```bash
ssh castillo-de-jagua
```

---

## Errors & Fixes

### ❌ `Permission denied (publickey)`
Your key isn't on the server yet, or the `IdentityFile` in your config points to the wrong key.

**Fix:**
- Check your key exists: `ls ~/.ssh/`
- Re-import via the Proxmox web UI shell: `ssh-import-id gh:your-github-username`
- Make sure `IdentityFile` in your config matches the actual key filename

---

### ❌ `401 Unauthorized` on `apt update` (Proxmox enterprise repo)
Proxmox defaults to the enterprise (paid) apt repository. Switch to the free repo:

```bash
# Disable enterprise repo
echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list

# Add free repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

apt update && apt upgrade -y
```

---

### ❌ Ceph enterprise repo also unauthorized
Same issue, separate file:

```bash
echo "# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise" > /etc/apt/sources.list.d/ceph.list

apt update && apt upgrade -y
```

---

### ❌ `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED`
You reinstalled the OS on the server, so its host key changed. SSH is protecting you from a potential attack, but in this case it's expected.

**Fix:** Remove the old host key from your laptop:
```bash
ssh-keygen -R <server-ip-or-hostname>
```
Then reconnect and accept the new host key.

---

### ❌ `Failed to connect to <host> after wake attempt`
The Wake-on-LAN packet was sent but the server never came up in time, or WoL isn't working.

**Check:**
- Wake-on-LAN is enabled in the server's **BIOS/UEFI**
- The MAC address in `wake-proxy.sh` is correct
- `wakeonlan` is installed on your laptop
- The server is plugged into ethernet (WoL does not work over Wi-Fi)

---

*🏴‍☠️ Nassau wasn't built in a day.*
