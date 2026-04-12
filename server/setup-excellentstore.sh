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
echo "[1/17] System basics..."
hostnamectl set-hostname "$HOSTNAME"
apt update && apt upgrade -y

# ── 2. Install packages ──────────────────────────────────────────
echo "[2/17] Installing packages..."
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
    avahi-daemon net-tools expect scrot

# Firefox ESR from Mozilla APT repo (Ubuntu only ships snap)
install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list
printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla
apt update && apt install -y firefox-esr
ln -sf /usr/bin/firefox-esr /usr/local/bin/firefox

# ── 3. Disable unnecessary services ──────────────────────────────
echo "[3/17] Disabling unnecessary services..."
systemctl disable --now apache2 2>/dev/null || true
systemctl disable --now postfix 2>/dev/null || true
systemctl disable --now snapd snapd.socket snapd.seeded.service 2>/dev/null || true
systemctl disable --now bluetooth 2>/dev/null || true
systemctl disable --now nfs-blkmap 2>/dev/null || true

# ── 4. Disable sleep/suspend (this is a server) ──────────────────
echo "[4/17] Disabling sleep/suspend..."
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
echo "[5/17] Reassembling RAID5 array..."
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
echo "[6/17] Configuring Samba..."
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
echo "[7/17] Configuring NFS..."
cat > /etc/exports << NFSEOF
$STORAGE_MOUNT $LAN_SUBNET(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
NFSEOF

exportfs -ra
systemctl enable --now nfs-kernel-server

# ── 8. SSH hardening (mirrors Hetzner production) ─────────────────
echo "[8/17] Hardening SSH..."
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
echo "[9/17] Configuring TigerVNC..."

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

# Set xfce4-terminal as default terminal emulator
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/xfce4-terminal 50
update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal

# Set Firefox ESR as default web browser (for XFCE taskbar launcher)
update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/firefox-esr 60
update-alternatives --set x-www-browser /usr/bin/firefox-esr
sudo -u "$USER" bash -c 'mkdir -p ~/.config/xfce4 && echo "WebBrowser=firefox" > ~/.config/xfce4/helpers.rc'
xdg-mime default firefox-esr.desktop x-scheme-handler/http x-scheme-handler/https text/html
usermod -aG video,render "$USER"

# Firefox ESR enterprise policies (disable telemetry, Pocket, onboarding)
mkdir -p /usr/lib/firefox-esr/distribution
cat > /usr/lib/firefox-esr/distribution/policies.json << 'POLICYEOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableFirefoxAccounts": true,
    "DisableFormHistory": true,
    "DontCheckDefaultBrowser": true,
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "NoDefaultBookmarks": true,
    "OverrideFirstRunPage": "",
    "OverridePostUpdatePage": "",
    "Homepage": {
      "URL": "https://duckduckgo.com",
      "StartPage": "homepage"
    },
    "FirefoxHome": {
      "Search": false, "TopSites": false, "SponsoredTopSites": false,
      "Highlights": false, "Pocket": false, "SponsoredPocket": false,
      "Snippets": false, "Locked": true
    },
    "UserMessaging": {
      "WhatsNew": false, "ExtensionRecommendations": false,
      "FeatureRecommendations": false, "MoreFromMozilla": false,
      "SkipOnboarding": true
    }
  }
}
POLICYEOF

# Firefox ESR user.js — low RAM, no GPU, dev tools enabled
# Profile is created on first run; deploy to skel-like location and copy on first launch
mkdir -p /opt/excellentstore/firefox-defaults
cat > /opt/excellentstore/firefox-defaults/user.js << 'FFUSERJS'
// === Developer Tools ===
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
user_pref("devtools.toolbox.host", "bottom");
user_pref("devtools.webconsole.persistlog", true);
user_pref("devtools.netmonitor.persistlog", true);

// === Hardware / Rendering (no GPU in VNC) ===
user_pref("gfx.canvas.accelerated", false);
user_pref("gfx.webrender.all", false);
user_pref("gfx.webrender.enabled", false);
user_pref("layers.acceleration.disabled", true);
user_pref("media.hardware-video-decoding.enabled", false);
user_pref("media.ffmpeg.vaapi.enabled", false);
user_pref("gfx.x11-egl.force-disabled", true);

// === Memory — aggressive reduction ===
user_pref("browser.cache.memory.capacity", 16384);
user_pref("browser.cache.memory.max_entry_size", 2048);
user_pref("browser.cache.disk.capacity", 32768);
user_pref("browser.cache.disk.smart_size.enabled", false);
user_pref("browser.sessionhistory.max_entries", 5);
user_pref("browser.sessionhistory.max_total_viewers", 0);
user_pref("browser.sessionstore.interval", 120000);
user_pref("browser.sessionstore.max_tabs_undo", 2);
user_pref("browser.sessionstore.max_windows_undo", 0);
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("javascript.options.mem.gc_incremental_slice_ms", 10);
user_pref("javascript.options.mem.high_water_mark", 32);
user_pref("javascript.options.mem.max", 256000);
user_pref("image.mem.surfacecache.max_size_kb", 32768);
user_pref("image.mem.surfacecache.min_expiration_ms", 30000);
user_pref("media.memory_cache_max_size", 8192);

// === Content processes — minimum ===
user_pref("dom.ipc.processCount", 1);
user_pref("dom.ipc.processCount.webIsolated", 1);
user_pref("dom.ipc.processCount.file", 1);
user_pref("dom.ipc.processCount.extension", 1);
user_pref("dom.ipc.processCount.privilegedabout", 1);
user_pref("dom.ipc.processCount.webCOOP+COEP", 1);
user_pref("fission.autostart", false);

// === Disable media autoplay & heavy codecs ===
user_pref("media.autoplay.default", 5);
user_pref("media.autoplay.blocking_policy", 2);
user_pref("media.av1.enabled", false);
user_pref("media.mediasource.enabled", false);

// === Network — no speculative loads ===
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.http.speculative-parallel-limit", 0);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.http.max-persistent-connections-per-server", 4);
user_pref("network.http.max-connections", 48);

// === UI — no animations ===
user_pref("general.smoothScroll", false);
user_pref("toolkit.cosmeticAnimations.enabled", false);
user_pref("ui.prefersReducedMotion", 1);
user_pref("browser.download.animateNotifications", false);
user_pref("browser.fullscreen.animate", false);
user_pref("browser.tabs.animate", false);

// === Disable telemetry ===
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.ping-centre.telemetry", false);
user_pref("beacon.enabled", false);

// === Disable unnecessary features ===
user_pref("extensions.pocket.enabled", false);
user_pref("reader.parse-on-load.enabled", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);
user_pref("browser.discovery.enabled", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("accessibility.force_disabled", 1);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("geo.enabled", false);

// === Homepage ===
user_pref("browser.startup.homepage", "https://duckduckgo.com");
user_pref("browser.startup.page", 1);
FFUSERJS

# Deploy user.js to existing profile if present, or instruct first-run copy
FIREFOX_PROFILE=$(find "/home/$USER/.mozilla/firefox" -maxdepth 1 -name '*.default-esr' -type d 2>/dev/null | head -1)
if [ -n "$FIREFOX_PROFILE" ]; then
    cp /opt/excellentstore/firefox-defaults/user.js "$FIREFOX_PROFILE/user.js"
    chown "$USER:$USER" "$FIREFOX_PROFILE/user.js"
fi

# ── 10. UFW Firewall ─────────────────────────────────────────────
echo "[10/17] Configuring firewall..."
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

# ZeroTier — SSH + SMB (trusted network)
ZT_IF=$(ip link show | grep -o 'zt[a-z0-9]*' | head -1)
if [ -n "$ZT_IF" ]; then
    ufw allow in on "$ZT_IF" to any port 22 proto tcp comment "ZeroTier SSH"
    ufw allow in on "$ZT_IF" to any port 139,445 proto tcp comment "ZeroTier SMB"
else
    echo "  Note: ZeroTier interface not yet active. After joining a network, run:"
    echo "  sudo ufw allow in on ztXXXXXXXX to any port 22 proto tcp comment 'ZeroTier SSH'"
    echo "  sudo ufw allow in on ztXXXXXXXX to any port 139,445 proto tcp comment 'ZeroTier SMB'"
fi

ufw --force enable
echo "  Firewall enabled."

# ── 11. Automatic security updates (mirrors Hetzner) ─────────────
echo "[11/17] Configuring automatic updates..."
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
echo "[12/17] Configuring weekly maintenance..."
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

# ── 13. NIC hardening (Intel i225/i226 igc driver) ───────────────
echo "[13/17] Hardening NIC (igc TX queue timeout fix)..."
cat > /etc/systemd/network/10-enp1s0.link << 'NICEOF'
# Fix igc (Intel i225/i226) transmit queue timeout hangs
# See: kernel NETDEV WATCHDOG errors on 2026-04-07
# Disable TSO/GSO (primary trigger) and increase ring buffers from 256 to 1024
[Match]
MACAddress=78:55:36:00:A3:E8
Driver=igc

[Link]
TCPSegmentationOffload=no
GenericSegmentationOffload=no
RxBufferSize=1024
TxBufferSize=1024
NICEOF

# Apply immediately (persistent config takes effect on next boot/link up)
if ethtool -i enp1s0 2>/dev/null | grep -q 'driver: igc'; then
    ethtool -K enp1s0 tso off gso off 2>/dev/null || true
    ethtool -G enp1s0 tx 1024 rx 1024 2>/dev/null || true
    echo "  igc NIC: TSO/GSO disabled, ring buffers 256→1024"
else
    echo "  Skipped: NIC is not using igc driver"
fi

# ── 14. ZeroTier VPN ──────────────────────────────────────────────
echo "[14/17] Installing ZeroTier..."
if ! command -v zerotier-cli &>/dev/null; then
    curl -s https://install.zerotier.com | bash
fi
systemctl enable --now zerotier-one
echo "  ZeroTier installed. Join a network with:"
echo "  sudo zerotier-cli join <network-id>"

# ZeroTier firewall rule already added in UFW section (SSH only on ZT interface)

# ── 15. Passwordless sudo ────────────────────────────────────────
echo "[15/17] Configuring passwordless sudo..."
cat > /etc/sudoers.d/tmds-nopasswd << 'SUDOEOF'
# SSH key-only auth is enforced — password not needed for sudo either
tmds ALL=(ALL) NOPASSWD: ALL
SUDOEOF
chmod 440 /etc/sudoers.d/tmds-nopasswd
visudo -c || { echo "SUDOERS CONFIG INVALID — removing"; rm /etc/sudoers.d/tmds-nopasswd; }
# Clean up old monitoring-only sudoers file if present
rm -f /etc/sudoers.d/monitoring

# ── 16. Avahi/mDNS + Cockpit ─────────────────────────────────────
echo "[16/17] Enabling mDNS and Cockpit..."
systemctl enable --now avahi-daemon
systemctl enable cockpit.socket

# ── 17. Podman + Media Stack ─────────────────────────────────────
echo "[17/17] Setting up Podman media stack..."
apt install -y podman
loginctl enable-linger "$USER"

# Directory structure on RAID storage (single mount for hardlinks)
mkdir -p "$STORAGE_MOUNT/media"/{downloads/{complete,incomplete},movies,tv,music}
mkdir -p "$STORAGE_MOUNT/media/appdata"/{prowlarr,sonarr,radarr,lidarr,qbittorrent,gluetun,plex}
chown -R "$USER:$USER" "$STORAGE_MOUNT/media"

# Deploy Quadlet files (systemd-native container management)
# Gluetun + qBittorrent run rootful (WireGuard needs kernel tun device)
# Prowlarr, Sonarr, Radarr, Lidarr, Plex run rootless under $USER
QUADLET_USER_DIR="/home/$USER/.config/containers/systemd"
QUADLET_ROOT_DIR="/etc/containers/systemd"
sudo -u "$USER" mkdir -p "$QUADLET_USER_DIR"
mkdir -p "$QUADLET_ROOT_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/deploy/media" ]; then
    # Rootful: gluetun + qbittorrent (VPN needs kernel access), plex (host networking for LAN speed)
    cp "$SCRIPT_DIR/deploy/media"/gluetun.container "$QUADLET_ROOT_DIR/"
    cp "$SCRIPT_DIR/deploy/media"/qbittorrent.container "$QUADLET_ROOT_DIR/"
    cp "$SCRIPT_DIR/deploy/media"/plex.container "$QUADLET_ROOT_DIR/"
    # Rootless: arr apps
    for f in prowlarr sonarr radarr lidarr; do
        cp "$SCRIPT_DIR/deploy/media/$f.container" "$QUADLET_USER_DIR/"
    done
    cp "$SCRIPT_DIR/deploy/media"/medianet.network "$QUADLET_USER_DIR/"
    chown -R "$USER:$USER" "$QUADLET_USER_DIR"
    echo "  Quadlet files deployed (gluetun+qbittorrent rootful, rest rootless)"
fi

# UFW rules — media stack (LAN only)
ufw allow from $LAN_SUBNET to any port 7878,8080,8686,8989,9696 proto tcp comment "Media Stack"
ufw allow from $LAN_SUBNET to any port 32400 proto tcp comment "Plex"

# Enable auto-updates for containers (rootless + rootful)
sudo -u "$USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$USER")" systemctl --user enable podman-auto-update.timer 2>/dev/null || true
systemctl enable podman-auto-update.timer 2>/dev/null || true

echo "  Podman installed. Media stack Quadlet files deployed."
echo "  Before starting containers:"
echo "    1. Set ProtonVPN WireGuard key in $QUADLET_ROOT_DIR/gluetun.container"
echo "    2. Get Plex claim token from https://plex.tv/claim, add to $QUADLET_USER_DIR/plex.container"
echo "    3. Start VPN + downloads + Plex: systemctl daemon-reload && systemctl start gluetun qbittorrent plex"
echo "    4. Start media apps:             sudo -u $USER XDG_RUNTIME_DIR=/run/user/\$(id -u $USER) systemctl --user daemon-reload"
echo "    5.                               sudo -u $USER XDG_RUNTIME_DIR=/run/user/\$(id -u $USER) systemctl --user start prowlarr sonarr radarr lidarr"

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
echo "Media Stack (after VPN + Plex token configured):"
echo "  Prowlarr:     http://ExcellentStore.local:9696"
echo "  Sonarr:       http://ExcellentStore.local:8989"
echo "  Radarr:       http://ExcellentStore.local:7878"
echo "  Lidarr:       http://ExcellentStore.local:8686"
echo "  qBittorrent:  http://ExcellentStore.local:8080"
echo "  Plex:         http://ExcellentStore.local:32400/web"
echo ""
echo "Maintenance:"
echo "  Daily:    unattended-upgrades (security patches)"
echo "  Weekly:   Sun 06:00 UTC (full upgrade + reboot)"
echo "  Reboot:   automatic at 06:00 UTC if kernel updated"
echo "  Containers: podman auto-update (daily, checks for new images)"
echo ""
echo "Remaining manual steps:"
echo "  1. Set VNC password:  sudo -u tmds vncpasswd"
echo "  2. Enable VNC:        sudo systemctl enable --now vncserver@1"
echo "  3. Copy SSH key:      ssh-copy-id -p $SSH_PORT tmds@ExcellentStore.local"
echo "  4. Join ZeroTier:     sudo zerotier-cli join <network-id>"
echo "  5. Authorize node in ZeroTier Central, then verify SSH works via ZT IP"
echo "  6. Set ProtonVPN WireGuard key in /etc/containers/systemd/gluetun.container"
echo "  7. Get Plex claim token from https://plex.tv/claim"
echo "  8. Start VPN+downloads+Plex: sudo systemctl start gluetun qbittorrent plex"
echo "  9. Start media apps:        systemctl --user start prowlarr sonarr radarr lidarr"
echo ""
