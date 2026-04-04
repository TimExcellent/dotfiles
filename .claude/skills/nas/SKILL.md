---
name: nas
description: Interact with the ExcellentStore NAS server — check health, RAID status, services, disk usage, firewall rules, and logs. Use this when the user asks about their NAS, home server, ExcellentStore, or storage server.
argument-hint: "[status|raid|disk|services|firewall|logs|vnc|info]"
---

# ExcellentStore NAS

## Server Overview

- **Hostname**: ExcellentStore
- **OS**: Ubuntu 24.04 LTS (on 64GB eMMC boot drive)
- **Storage**: 4x NVMe in RAID5 (md127), ~5.6TB usable, mounted at `/mnt/storage`
- **RAID UUID**: 5b913ff5:c2c12e53:94a68f67:982f78f0
- **FS UUID**: 62b51ab2-009c-458e-b329-21c1beee766c
- **User**: tmds

## Connection

Two SSH hosts are configured in `~/.ssh/config`. Always try LAN first (faster), fall back to ZeroTier:

```bash
# Try LAN first (short timeout), fall back to ZeroTier
ssh -o ConnectTimeout=3 excellentstore "COMMAND" 2>/dev/null || ssh -o ConnectTimeout=5 excellentstore-zt "COMMAND"
```

| Host | Network | IP | Port | Use when |
|------|---------|-----|------|----------|
| `excellentstore` | LAN | 192.168.50.60 | 58276 | On home network |
| `excellentstore-zt` | ZeroTier | 10.242.237.138 | 22 | Remote / away from home |

- **SSH key**: `~/.ssh/id_ed25519_excellentstore`
- **Auth**: Key-only (no passwords), root login disabled, MaxAuthTries 3

## Passwordless sudo

The following monitoring commands run without a password via `/etc/sudoers.d/monitoring`:
- `sudo ufw status [numbered|verbose]`
- `sudo mdadm --detail /dev/md*`
- `sudo systemctl status *`
- `sudo journalctl *`
- `sudo smartctl -a /dev/nvme*`

## Services

| Service | Port | Access | Check command |
|---------|------|--------|---------------|
| SSH | 58276 (LAN), 22 (ZeroTier) | Anywhere / ZeroTier | `systemctl status ssh` |
| Samba (SMB) | 139, 445 | LAN + ZeroTier | `sudo systemctl status smbd nmbd` |
| NFS | 111, 2049 | LAN only | `sudo systemctl status nfs-kernel-server` |
| Cockpit | 9090 | LAN only | `sudo systemctl status cockpit.socket` |
| TigerVNC | 5901 (localhost) | SSH tunnel only | `sudo systemctl status vncserver@1` |
| ZeroTier | — | Outbound | `sudo systemctl status zerotier-one` |
| Avahi/mDNS | 5353 | LAN | `sudo systemctl status avahi-daemon` |

### Accessing services from Mac

- **SMB (LAN)**: `smb://ExcellentStore.local/bigdrive` or `smb://192.168.50.60/bigdrive`
- **SMB (Remote)**: `smb://10.242.237.138/bigdrive` (via ZeroTier)
- **NFS**: `mount ExcellentStore.local:/mnt/storage /mnt/nas`
- **Cockpit**: `https://ExcellentStore.local:9090` (LAN only)
- **VNC (LAN)**: `~/Desktop/VNC-ExcellentStore.command` — tunnels via SSH port 58276
- **VNC (Remote)**: `~/Desktop/VNC-ExcellentStore-Remote.command` — tunnels via ZeroTier SSH port 22

## Firewall (UFW)

Default deny incoming, allow outgoing. Rules:
- SSH 58276/tcp from anywhere
- SSH 22/tcp on ZeroTier interface only
- SMB 139,445/tcp from 192.168.50.0/24
- SMB 139,445/tcp on ZeroTier interface
- NFS 111,2049/tcp+udp from 192.168.50.0/24
- Cockpit 9090/tcp from 192.168.50.0/24

## Maintenance schedule

- **Daily**: unattended-upgrades (security patches + noble-updates)
- **Weekly**: Sun 06:00 UTC — full apt upgrade + reboot (`excellentstore-maintenance.timer`)
- **Auto-reboot**: 06:00 UTC if kernel updated (after Hetzner prod 03:00, dev 05:00)

## Commands by subcommand

When the user invokes `/nas`, look at `$ARGUMENTS` and run the matching commands below. If no argument given, run a quick health dashboard (status).

### `status` or no argument — Quick health dashboard

```bash
echo "=== ExcellentStore Health ===" && \
uptime && echo "---" && \
cat /proc/mdstat && echo "---" && \
df -h /mnt/storage /dev/mmcblk0p2 && echo "---" && \
free -h && echo "---" && \
systemctl is-active ssh smbd nmbd nfs-server cockpit.socket vncserver@1 zerotier-one avahi-daemon | paste - - - - - - - - && \
echo "Services: ssh smbd nmbd nfs cockpit vnc zerotier avahi" && echo "---" && \
sudo ufw status | head -3
```

### `raid` — RAID5 array health

```bash
cat /proc/mdstat && echo "---" && \
sudo mdadm --detail /dev/md127 && echo "---" && \
df -h /mnt/storage
```

### `disk` — Storage usage breakdown

```bash
df -h /mnt/storage /dev/mmcblk0p2 && echo "---" && \
du -sh /mnt/storage/*/ 2>/dev/null | sort -rh | head -20
```

### `services` — All service statuses

```bash
for svc in ssh smbd nmbd nfs-kernel-server cockpit.socket vncserver@1 zerotier-one avahi-daemon; do
    printf "%-25s %s\n" "$svc" "$(systemctl is-active $svc)"
done && echo "---" && \
sudo systemctl list-timers --no-pager | grep -E "excellent|unattended"
```

### `firewall` — UFW rules

```bash
sudo ufw status numbered
```

### `logs` — Recent system logs

```bash
sudo journalctl -n 50 --no-pager -p warning
```

If $ARGUMENTS contains a service name after `logs`, filter to that:
```bash
sudo journalctl -u SERVICE_NAME -n 50 --no-pager
```

### `vnc` — VNC status and info

```bash
sudo systemctl status vncserver@1 --no-pager -l
```

Then remind the user:
- LAN: run `~/Desktop/VNC-ExcellentStore.command`
- Remote: run `~/Desktop/VNC-ExcellentStore-Remote.command`
- Or manually: `ssh -L 5901:localhost:5901 excellentstore` then `open vnc://localhost:5901`

### `info` — Print server summary

Don't SSH. Just print the server overview, connection details, and service table from this skill file.

## Config files on server

| File | Purpose |
|------|---------|
| `/etc/ssh/sshd_config` | Hardened SSH config |
| `/etc/systemd/system/ssh.socket.d/override.conf` | SSH port 58276 |
| `/etc/samba/smb.conf` | Samba share config (bigdrive) |
| `/etc/exports` | NFS exports |
| `/etc/ufw/user.rules` | Firewall rules |
| `/etc/apt/apt.conf.d/50unattended-upgrades` | Auto security updates |
| `/etc/systemd/system/excellentstore-maintenance.timer` | Weekly reboot timer |
| `/opt/excellentstore/bin/run-maintenance` | Weekly maintenance script |
| `/home/tmds/.vnc/xstartup` | VNC desktop session (XFCE) |
| `/etc/systemd/system/vncserver@.service` | VNC systemd unit |

## Dotfiles repo

Server config is tracked in the dotfiles repo at:
- `server/setup-excellentstore.sh` — full post-install setup script
- `server/autoinstall/user-data` — cloud-init autoinstall config
- `server/create-usb-installer.sh` — bootable USB builder

## Error handling

- If both SSH connections fail, tell the user the server may be off, sleeping, or unreachable. The server should NOT sleep (systemd targets are masked) — if it does, that's a bug.
- If a service is inactive/failed, show the full status and recent logs for that service.
- For RAID degraded state ([UU_U] or similar in mdstat), flag this prominently as urgent.
