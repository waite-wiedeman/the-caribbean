# 🏰 Proxmox Setup — *Castillo de Jagua*
> Getting a Proxmox VE hypervisor up and running from scratch, ready to host VMs across the Caribbean.

---

## 📋 Table of Contents
- [ISO Selection](#iso-selection)
- [Installation Walkthrough](#installation-walkthrough)
- [First Login & Web UI](#first-login--web-ui)
- [Fixing apt Repos](#fixing-apt-repos)
- [Wake-on-LAN & BIOS Notes](#wake-on-lan--bios-notes)
- [SSH Setup](#ssh-setup)
- [Errors & Fixes](#errors--fixes)

---

## ISO Selection

Download **Proxmox VE 8.x** (the latest 8.x release) from the [official Proxmox downloads page](https://www.proxmox.com/en/downloads).

| Version | Verdict |
|---|---|
| 6.x | ❌ Old, approaching end of life |
| 7.x | ❌ Older, no reason to start here |
| **8.x** | ✅ **Get this one** — stable, well-documented, huge community |
| 9.x | ⚠️ Too new — fewer guides, less community support |

> 💡 Always prefer the latest *stable* release over the bleeding edge. 8.x has the best balance of features, stability, and available documentation.

Flash the ISO to a USB drive with [Balena Etcher](https://etcher.balena.io/) or [Ventoy](https://www.ventoy.net/).

---

## Installation Walkthrough

### Boot Menu
On first boot you'll be presented with three options:

| Option | Use case |
|---|---|
| **Graphical** | ✅ Pick this — easiest, mouse support, beginner friendly |
| Terminal UI | For servers without a proper display |
| Terminal UI, Serial Console | For headless/remote-managed hardware only |

### Network Configuration
The installer will prompt for network settings. Here's what to enter:

- **Hostname (FQDN)** — A local name for your machine. Format: `hostname.local` or `hostname.home`. Example: `castillo-de-jagua.caribbean`
  > 💡 `.caribbean` (or any made-up TLD) is fine for a local homelab as long as you run your own local DNS later. It won't resolve on the public internet.
- **IP Address** — Set a **static IP** outside your router's DHCP range so nothing else claims it. If one is pre-filled from a previous OS install, you can keep it.
- **Gateway** — Your router's IP, typically `192.168.1.1` or `192.168.0.1`. Confirm on your laptop with:
  ```bash
  ip route | grep default
  ```
- **DNS Server** — Your router's IP works here too, or use a public DNS:
  - `1.1.1.1` — Cloudflare
  - `8.8.8.8` — Google

### Storage & Everything Else
- Proxmox will wipe and partition the drive itself — the defaults are fine for a first install
- Set a strong root password when prompted — you'll use this to log into the web UI

> ⚠️ **Note:** There is no separate user account created during install. `root` is your account.

---

## First Login & Web UI

Once installed and booted, open a browser on your laptop and navigate to:

```
https://<your-static-ip>:8006
```

> Your browser will warn about an untrusted certificate — this is expected. Accept and proceed.

**Login credentials:**
- **Username:** `root`
- **Password:** whatever you set during install
- **Realm:** `Linux PAM standard authentication`

### The "No Valid Subscription" Popup
You'll see a nag popup on every login. Just click **OK** — Proxmox is fully functional without a paid subscription. Fixing the apt repos (next section) will reduce this.

### Web UI vs. Terminal
Almost everything is done in the browser. The terminal (SSH or the built-in **Shell** button in the web UI) is only needed for:
- Fixing apt repos
- Occasional config file edits
- Troubleshooting

> 💡 The web UI has a built-in shell under **Shell** in the node menu — you don't even need to SSH in for most terminal tasks.

---

## Fixing apt Repos

Proxmox ships configured to use the **enterprise (paid) apt repository**. Without a subscription this causes errors on `apt update`. Switch to the free community repo:

### 1. Disable the enterprise PVE repo
```bash
echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
```

### 2. Add the free repo
```bash
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
```

### 3. Disable the enterprise Ceph repo
Proxmox also ships a separate enterprise repo for Ceph that needs to be disabled:
```bash
echo "# deb https://enterprise.proxmox.com/debian/ceph-quincy bookworm enterprise" > /etc/apt/sources.list.d/ceph.list
```

### 4. Update
```bash
apt update && apt upgrade -y
```

---

## Wake-on-LAN & BIOS Notes

Wake-on-LAN (WoL) lets you boot the server remotely over the network without physically pressing the power button. This is essential for a homelab you don't want running 24/7.

### Enable WoL in BIOS/UEFI
- Boot into BIOS/UEFI (usually `Del`, `F2`, or `F12` on POST)
- Find the Wake-on-LAN setting — usually under **Power Management** or **Advanced**
- Enable it and save

### Other useful BIOS settings to consider
- **Restore on AC Power Loss** — set to "Power On" if you want the server to come back up automatically after a power outage

### Note your MAC address
You'll need your server's MAC address for the WoL script. Find it with:
```bash
ip a
```
Look for the `link/ether` line on your ethernet interface (e.g. `enp3s0`). It looks like `a8:a1:59:xx:xx:xx`.

> 💡 Also note the interface name (e.g. `enp3s0`) — you'll need it later for network/VLAN configuration.

> ⚠️ Wake-on-LAN **does not work over Wi-Fi** — the server must be on ethernet.

---

## SSH Setup

SSH is enabled on Proxmox by default — no configuration needed to get started. For full SSH setup including key-based authentication, disabling password auth, and the Wake-on-LAN ProxyCommand, see the [SSH README](../ssh/README.md).

---

## Errors & Fixes

### ❌ `401 Unauthorized` on `apt update`
You're hitting the enterprise repo without a subscription. See [Fixing apt Repos](#fixing-apt-repos) above.

---

### ❌ Browser says "Your connection is not private" on `:8006`
This is expected — Proxmox uses a self-signed certificate by default. Click **Advanced → Proceed** to continue. It's safe in a local network context.

---

### ❌ Can't reach the web UI at `:8006`
- Make sure you're using `https://` not `http://`
- Confirm the static IP you set during install matches what you're typing
- Make sure the server finished booting — give it a full minute after power on

---

### ❌ Forgot root password
Boot into recovery mode or use a live USB to chroot into the system and reset it with `passwd`.

---

*🏴‍☠️ The prize is worth the voyage.*
