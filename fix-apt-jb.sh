#!/usr/bin/env bash
set -euo pipefail

# fix-apt-jb.sh
# Defensive APT repair helper for palera1n/rootless iOS jailbreak.
# It does NOT bypass signature verification.

export PATH="/var/jb/usr/bin:/var/jb/usr/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

BACKUP_DIR="$HOME/apt-backup-$(date +%Y%m%d-%H%M%S)"
PACKAGES=(
  inetutils-tools
  inetutils-ping
  inetutils-traceroute
  inetutils-whois
  lsof
  tcpdump
  curl
  wget
)

log() {
  printf '[+] %s\n' "$*"
}

warn() {
  printf '[!] %s\n' "$*" >&2
}

die() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

need_cmd apt
need_cmd dpkg
need_cmd find
need_cmd date

log "Running as: $(id 2>/dev/null || true)"
log "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

log "Backing up APT configuration..."
for path in \
  /etc/apt/sources.list \
  /etc/apt/sources.list.d \
  /var/jb/etc/apt/sources.list \
  /var/jb/etc/apt/sources.list.d
do
  if [ -e "$path" ]; then
    safe_name="$(echo "$path" | sed 's#/#_#g')"
    cp -a "$path" "$BACKUP_DIR/$safe_name"
    log "Backed up: $path"
  fi
done

log "Current APT sources:"
find /etc/apt /var/jb/etc/apt \
  \( -name "*.list" -o -name "*.sources" \) \
  -type f 2>/dev/null \
  -print \
  -exec sh -c 'echo "--- $1"; sed -n "1,120p" "$1"' sh {} \; || true

log "Cleaning old APT list cache..."
rm -rf /var/lib/apt/lists/* 2>/dev/null || true
rm -rf /var/jb/var/lib/apt/lists/* 2>/dev/null || true

log "First apt update test..."
set +e
apt update
APT_STATUS=$?
set -e

if [ "$APT_STATUS" -ne 0 ]; then
  warn "apt update failed. Trying to refresh known keyring packages if available..."

  # These names vary between jailbreak bootstraps/repos.
  # The loop only installs packages that APT can actually see.
  KEYRING_CANDIDATES=(
    palera1n-keyring
    procursus-keyring
    bigboss-keyring
    ellekit
    sileo
  )

  for pkg in "${KEYRING_CANDIDATES[@]}"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      log "Attempting reinstall/install of: $pkg"
      set +e
      apt install --reinstall -y "$pkg"
      REINSTALL_STATUS=$?
      set -e

      if [ "$REINSTALL_STATUS" -ne 0 ]; then
        warn "Could not reinstall $pkg. Continuing."
      fi
    else
      warn "Package not visible in APT cache: $pkg"
    fi
  done

  log "Cleaning APT list cache again..."
  rm -rf /var/lib/apt/lists/* 2>/dev/null || true
  rm -rf /var/jb/var/lib/apt/lists/* 2>/dev/null || true

  log "Second apt update test..."
  apt update || {
    warn "apt update still fails."
    warn "Do this manually in Sileo:"
    warn "1. Sources -> Refresh"
    warn "2. Remove and re-add repo.palera.in"
    warn "3. Remove BigBoss temporarily if it still throws NO_PUBKEY"
    warn "4. Run: sudo apt update"
    warn "Backup saved at: $BACKUP_DIR"
    exit 2
  }
fi

log "apt update is OK."

log "Installing network/tool packages..."
apt install -y "${PACKAGES[@]}"

log "Installed package check:"
for pkg in "${PACKAGES[@]}"; do
  dpkg -l "$pkg" 2>/dev/null | awk 'NR==1 || /^ii/ {print}'
done

log "Command availability:"
for cmd in ping traceroute whois lsof tcpdump curl wget ipconfig; do
  if command -v "$cmd" >/dev/null 2>&1; then
    printf 'OK   %s -> %s\n' "$cmd" "$(command -v "$cmd")"
  else
    printf 'MISS %s\n' "$cmd"
  fi
done

log "Basic tests:"
if command -v ipconfig >/dev/null 2>&1; then
  printf 'Wi-Fi IP en0: '
  ipconfig getifaddr en0 2>/dev/null || true
fi

log "Done."
log "APT backup: $BACKUP_DIR"
