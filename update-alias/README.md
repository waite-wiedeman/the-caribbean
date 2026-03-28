# 🔄 Update Alias — *Castillo de Jagua*
> A simple terminal alias to keep the ship seaworthy.

---

## What It Does

Typing `update` in the terminal runs a full system update chain:

```bash
apt update && apt full-upgrade -y && apt autoremove -y && apt clean
```

| Command | Purpose |
|---|---|
| `apt update` | Refreshes the package index |
| `apt full-upgrade -y` | Upgrades all packages, handling dependency changes |
| `apt autoremove -y` | Removes packages that are no longer needed |
| `apt clean` | Clears the local package cache |

---

## Setup

Add the alias to your shell config:

```bash
echo "alias update='apt update && apt full-upgrade -y && apt autoremove -y && apt clean'" >> ~/.bashrc
```

Reload your shell to activate it immediately:

```bash
source ~/.bashrc
```

---

## Usage

```bash
update
```

That's it. 🏴‍☠️

---

## Notes

- The alias is saved in `~/.bashrc` and persists across reboots and new SSH sessions
- `>>` appends to the file without overwriting anything else in it
- To remove the alias, open `~/.bashrc` and delete the `alias update=...` line
