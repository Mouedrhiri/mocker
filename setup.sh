#!/usr/bin/env bash
# One-time mocker environment setup — run as root in WSL
set -euo pipefail

echo "Setting up mocker environment..."

# 1. Strip Windows line endings from mocker
sed -i 's/\r//' /mnt/c/Users/mouedrhiri/Desktop/mocker/mocker

# 2. Install mocker to PATH
cp /mnt/c/Users/mouedrhiri/Desktop/mocker/mocker /usr/local/bin/mocker
chmod +x /usr/local/bin/mocker
echo "[OK] mocker installed at /usr/local/bin/mocker"

# 3. Mount BTRFS volume (skip if already mounted)
if ! mountpoint -q /var/mocker 2>/dev/null; then
    [[ ! -f /var/btrfs.img ]] && fallocate -l 5G /var/btrfs.img
    mkdir -p /var/mocker
    mkfs.btrfs -f /var/btrfs.img
    mount -o loop /var/btrfs.img /var/mocker
    echo "[OK] BTRFS mounted at /var/mocker"
else
    echo "[OK] BTRFS already mounted at /var/mocker"
fi

# 4. Set up bridge0 (skip if it already exists)
if ! ip link show bridge0 &>/dev/null; then
    ip link add bridge0 type bridge
    ip addr add 10.0.0.1/24 dev bridge0
    ip link set bridge0 up
    echo "[OK] bridge0 created (10.0.0.1/24)"
else
    echo "[OK] bridge0 already exists"
fi

# 5. Enable IP forwarding + NAT
echo 1 > /proc/sys/net/ipv4/ip_forward
DEFAULT_IF=$(ip route | awk '/^default/ {print $5; exit}')
iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -j MASQUERADE 2>/dev/null || true
echo "[OK] IP forwarding + NAT enabled (via $DEFAULT_IF)"

echo ""
echo "============================================"
echo "  mocker is ready!  Made by Mohammed Ouedrhiri"
echo "  Try: mocker pull alpine latest"
echo "============================================"
