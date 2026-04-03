#!/usr/bin/env bash
# setup-excellentstore.sh — Post-install configuration for ExcellentStore NAS
# Run as root after Ubuntu 24.04 LTS fresh install on eMMC
# Mirrors Hetzner production server hardening from tickplungedotcom repo.
# Usage: sudo bash setup-excellentstore.sh
set -euo pipefail

HOSTNAME="ExcellentStore"
USER="tmds"
STORAGE_MOUNT="/mnt/storage"
RAID_UUID="5b913ff5:c2c12e53:94a68f67:982f78f0"
FS_UUID="62b51ab2-009c-458e-b329-21c1beee766c"
LAN_SUBNET="192.168.50.0/24"
SSH_PORT="58276"

echo "=== ExcellentStore NAS Setup ==="
echo "Target: Ubuntu 24.04 LTS on eMMC with 4x NVMe RAID5"
echo ""

# ── 1. System basics ──────────────────────────────────────────────
echo "[1/13] System basics..."
hostnamectl set-hostname "$HOSTNAME"
apt update && apt upgrade -y

# ── 2. Install packages ──────────────────────────────────────────
echo "[2/13] Installing packages..."
apt install -y \
    openssh-server \
    xfce4 xfce4-goodies dbus-x11 \
    tigervnc-standalone-server tigervnc-common \
    samba nfs-kernel-server \
    cockpit \
    mdadm \
    ufw \
    unattended-upgrades apt-listchanges \
    htop tmux vim curl wget git \
    avahi-daemon net-tools expect

# ── 3. Disable unnecessary services ──────────────────────────────
echo "[3/13] Disabling unnecessary services..."
systemctl disable --now apache2 2>/dev/null || true
systemctl disable --now postfix 2>/dev/null || true
systemctl disable --now snapd snapd.socket snapd.seeded.service 2>/dev/null || true

# ── 4. Disable sleep/suspend (this is a server) ──────────────────
echo "[4/13] Disabling sleep/suspend..."
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/nosuspend.conf << 'LIDEOF'
[Login]
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
LIDEOF
systemctl restart systemd-logind

# ── 5. RAID5 reassembly ──────────────────────────────────────────
echo "[5/13] Reassembling RAID5 array..."
mkdir -p "$STORAGE_MOUNT"

grep -q "$RAID_UUID" /etc/mdadm/mdadm.conf 2>/dev/null || \
    echo "ARRAY /dev/md/ExcellentStore:raid0 UUID=$RAID_UUID" >> /etc/mdadm/mdadm.conf

if ! grep -q md127 /proc/mdstat 2>/dev/null && ! grep -q md0 /proc/mdstat 2>/dev/null; then
    mdadm --assemble --scan || true
fi

grep -q "$FS_UUID" /etc/fstab || \
    echo "UUID=$FS_UUID $STORAGE_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab

mount -a 2>/dev/null || true
update-initramfs -u

echo "  RAID status:"
cat /proc/mdstat

# ── 6. Samba (SMB) — Mac/Windows file sharing ────────────────────
echo "[6/13] Configuring Samba..."
cat > /etc/samba/smb.conf << 'SMBEOF'
[global]
    workgroup = WORKGROUP
    server string = ExcellentStore Samba Server
    netbios name = ExcellentStore
    server role = standalone server

    # Security and authentication
    map to guest = Bad User
    guest account = nobody

    # Logging
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file

    # Disable printers
    load printers = no
    printing = bsd

    # Performance
    socket options = TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072

    # Mac compatibility — disable problematic ACL features
    nt acl support = no
    inherit acls = no
    map acl inherit = no
    store dos attributes = no

    # SMB protocol versions
    server min protocol = SMB2
    client min protocol = SMB2

[bigdrive]
    comment = Network Storage
    path = /mnt/storage
    browsable = yes

    # Access control
    guest ok = yes
    read only = no

    # Force consistent permissions
    force user = nobody
    force group = nogroup
    create mask = 0666
    directory mask = 0777
    force create mode = 0666
    force directory mode = 0777

    # Disable inheritance that causes Mac issues
    inherit permissions = no
    inherit acls = no

    # Mac-specific VFS modules and settings
    vfs objects = catia fruit streams_xattr

    # Fruit (Apple) settings for better Mac compatibility
    fruit:aapl = yes
    fruit:nfs_aces = no
    fruit:copyfile = no
    fruit:model = MacSamba
    fruit:posix_rename = yes
    fruit:veto_appledouble = no
    fruit:wipe_intentionally_left_blank_rfork = yes
    fruit:delete_empty_adfiles = yes

    # Hide .DS_Store and other Mac files
    veto files = /._*/.DS_Store/
    delete veto files = yes
SMBEOF

systemctl enable --now smbd nmbd
systemctl restart smbd nmbd

# ── 7. NFS — Linux file sharing ──────────────────────────────────
echo "[7/13] Configuring NFS..."
cat > /etc/exports << NFSEOF
$STORAGE_MOUNT $LAN_SUBNET(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
NFSEOF

exportfs -ra
systemctl enable --now nfs-kernel-server

# ── 8. SSH hardening (mirrors Hetzner production) ─────────────────
echo "[8/13] Hardening SSH..."
systemctl enable --now ssh

# Hardened sshd_config — matches Hetzner production pattern
cat > /etc/ssh/sshd_config << 'SSHEOF'
Include /etc/ssh/sshd_config.d/*.conf

# Host Keys — only strong algorithms
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Authentication
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
MaxAuthTries 3
LoginGraceTime 30s

# Security
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
UsePAM yes

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

# Random high port via systemd socket override (Ubuntu 24.04 pattern)
mkdir -p /etc/systemd/system/ssh.socket.d
cat > /etc/systemd/system/ssh.socket.d/override.conf << SOCKETEOF
[Socket]
ListenStream=
ListenStream=0.0.0.0:${SSH_PORT}
ListenStream=[::]:${SSH_PORT}
SOCKETEOF

sshd -t || { echo "SSHD CONFIG INVALID — aborting"; exit 1; }
systemctl daemon-reload
systemctl restart ssh.socket ssh.service

# Ensure key directory exists for user
sudo -u "$USER" mkdir -p "/home/$USER/.ssh"
chmod 700 "/home/$USER/.ssh"
chown "$USER:$USER" "/home/$USER/.ssh"

echo "  SSH hardened on port $SSH_PORT. Add your key with:"
echo "  ssh-copy-id -p $SSH_PORT $USER@ExcellentStore.local"

# ── 9. TigerVNC + XFCE ──────────────────────────────────────────
echo "[9/13] Configuring TigerVNC..."

sudo -u "$USER" mkdir -p "/home/$USER/.vnc"

# xstartup — matches Hetzner server pattern
cat > "/home/$USER/.vnc/xstartup" << 'VNCEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
exec dbus-launch --exit-with-session startxfce4
VNCEOF
chmod +x "/home/$USER/.vnc/xstartup"
chown -R "$USER:$USER" "/home/$USER/.vnc"

# systemd service — template unit matching Hetzner pattern
cat > /etc/systemd/system/vncserver@.service << 'VNCSERVICE'
[Unit]
Description=TigerVNC server on display %i
After=syslog.target network.target

[Service]
Type=forking
User=tmds
ExecStartPre=/bin/sh -c "/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || true"
ExecStart=/usr/bin/vncserver -depth 24 -geometry 1920x1080 :%i
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
VNCSERVICE

systemctl daemon-reload

echo "  VNC service created. Set password and enable with:"
echo "  sudo -u $USER vncpasswd && sudo systemctl enable --now vncserver@1"

# ── 10. UFW Firewall ─────────────────────────────────────────────
echo "[10/13] Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH on hardened port
ufw allow ${SSH_PORT}/tcp comment "SSH"

# NAS services — LAN only
ufw allow from $LAN_SUBNET to any port 139,445 proto tcp comment "SMB"
ufw allow from $LAN_SUBNET to any port 111,2049 proto tcp comment "NFS"
ufw allow from $LAN_SUBNET to any port 111,2049 proto udp comment "NFS UDP"

# Cockpit — LAN only
ufw allow from $LAN_SUBNET to any port 9090 proto tcp comment "Cockpit"

# Tailscale interface (when installed)
ufw allow in on tailscale0 2>/dev/null || true

ufw --force enable
echo "  Firewall enabled."

# ── 11. Automatic security updates (mirrors Hetzner) ─────────────
echo "[11/13] Configuring automatic updates..."
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'APTEOF'
// Includes noble-updates because security patches are often listed there.
// Reboot at 06:00 UTC (after Hetzner prod 03:00, dev 05:00).
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "06:00";

Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::MailReport "only-on-error";
APTEOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'APTEOF2'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
APTEOF2

# ── 12. Weekly maintenance timer (mirrors Hetzner) ───────────────
echo "[12/13] Configuring weekly maintenance..."
mkdir -p /opt/excellentstore/bin

cat > /opt/excellentstore/bin/run-maintenance << 'MAINTEOF'
#!/bin/bash
set -e

logger -t excellentstore-maintenance "Starting weekly maintenance..."

# Update package lists
apt-get update -qq

# Install all available updates non-interactively
# --force-confdef/confold: keep existing config files, don't prompt
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold"

# Remove unused packages
apt-get autoremove -y -qq

# Clean apt cache
apt-get autoclean -qq

logger -t excellentstore-maintenance "Updates applied, rebooting..."

# Reboot — all services auto-start via systemd
/sbin/reboot
MAINTEOF
chmod +x /opt/excellentstore/bin/run-maintenance

cat > /etc/systemd/system/excellentstore-maintenance.service << 'SVCEOF'
[Unit]
Description=ExcellentStore Weekly Maintenance (upgrade + reboot)
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/excellentstore/bin/run-maintenance
SVCEOF

cat > /etc/systemd/system/excellentstore-maintenance.timer << 'TMREOF'
[Unit]
Description=ExcellentStore Weekly Maintenance Timer

[Timer]
OnCalendar=Sun 06:00:00 UTC
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
TMREOF

systemctl daemon-reload
systemctl enable --now excellentstore-maintenance.timer

# ── 13. Avahi/mDNS + Cockpit ─────────────────────────────────────
echo "[13/13] Enabling mDNS and Cockpit..."
systemctl enable --now avahi-daemon
systemctl enable cockpit.socket

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Services:"
echo "  SSH:      ssh -p $SSH_PORT tmds@ExcellentStore.local"
echo "  SMB:      smb://ExcellentStore.local/bigdrive"
echo "  NFS:      mount ExcellentStore.local:/mnt/storage /mnt/nas"
echo "  Cockpit:  https://ExcellentStore.local:9090"
echo "  VNC:      ssh -p $SSH_PORT -L 5901:localhost:5901 tmds@ExcellentStore.local"
echo "            then connect VNC viewer to localhost:5901"
echo ""
echo "Maintenance:"
echo "  Daily:    unattended-upgrades (security patches)"
echo "  Weekly:   Sun 06:00 UTC (full upgrade + reboot)"
echo "  Reboot:   automatic at 06:00 UTC if kernel updated"
echo ""
echo "Remaining manual steps:"
echo "  1. Set VNC password:  sudo -u tmds vncpasswd"
echo "  2. Enable VNC:        sudo systemctl enable --now vncserver@1"
echo "  3. Copy SSH key:      ssh-copy-id -p $SSH_PORT tmds@ExcellentStore.local"
echo "  4. Install Tailscale: curl -fsSL https://tailscale.com/install.sh | sh"
echo ""
