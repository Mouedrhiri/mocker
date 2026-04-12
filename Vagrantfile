$script = <<SCRIPT
set -e

# ── Packages ──────────────────────────────────────────────────────────────
dnf install -y -q \
  btrfs-progs curl iproute iptables libcgroup-tools \
  python3 util-linux uuidgen e2fsprogs

# ── BTRFS volume for mocker ───────────────────────────────────────────────
fallocate -l 10G /var/btrfs.img
mkdir -p /var/mocker
mkfs.btrfs /var/btrfs.img
mount -o loop /var/btrfs.img /var/mocker

# Persist the mount across reboots
echo "/var/btrfs.img /var/mocker btrfs loop 0 0" >> /etc/fstab

# ── mocker binary ─────────────────────────────────────────────────────────
chmod +x /vagrant/mocker
ln -sf /vagrant/mocker /usr/bin/mocker

# ── Networking: bridge0 + NAT ─────────────────────────────────────────────
ip link add bridge0 type bridge
ip addr add 10.0.0.1/24 dev bridge0
ip link set bridge0 up

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables --flush
# NAT outbound traffic from containers through the host's default interface
DEFAULT_IF=$(ip route | awk '/^default/ {print $5; exit}')
iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -j MASQUERADE
iptables -A FORWARD -i bridge0 -j ACCEPT
iptables -A FORWARD -o bridge0 -j ACCEPT

echo ""
echo "========================================="
echo "  mocker is ready!  Try: mocker --help"
echo "========================================="
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box     = "generic/centos9s"
  config.vm.box_version = ">= 4.0.0"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus   = 2
    # Enable promiscuous mode on the NIC so bridge0 can forward packets
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  end

  config.vm.provision "shell", inline: $script
end
