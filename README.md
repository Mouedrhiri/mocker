# Mocker
Docker implemented in ~300 lines of bash. Inspired by [bocker](https://github.com/p8952/bocker), updated with Docker Hub v2 API support and extra commands.

**Made by: Mohammed Ouedrhiri**

  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
  * [Example Usage](#example-usage)
  * [Functionality: Currently Implemented](#functionality-currently-implemented)
  * [Functionality: Not Yet Implemented](#functionality-not-yet-implemented)
  * [License](#license)

## Prerequisites

The following packages are needed to run mocker.

* btrfs-progs
* curl
* iproute2
* iptables
* libcgroup-tools
* python3
* util-linux >= 2.25.2
* coreutils >= 7.5

Additionally your system will need to be configured with the following:

* A btrfs filesystem mounted under `/var/mocker`
* A network bridge called `bridge0` and an IP of `10.0.0.1/24`
* IP forwarding enabled in `/proc/sys/net/ipv4/ip_forward`
* A firewall routing traffic from `bridge0` to a physical interface.

**Always run mocker inside a virtual machine.** It runs as root and modifies network interfaces, routing tables, and firewall rules.

## Installation

### Option 1 — Vagrant (recommended, works on Windows/macOS/Linux)

1. Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
2. Install [Vagrant](https://developer.hashicorp.com/vagrant/downloads)
3. From the project directory run:

```bash
vagrant up
vagrant ssh
```

The VM will automatically:
- Create a 10 GB BTRFS volume mounted at `/var/mocker`
- Set up `bridge0` networking with NAT
- Install all required packages
- Symlink `mocker` into `/usr/bin/mocker`

### Option 2 — Native Linux

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt-get install btrfs-progs curl iproute2 iptables libcgroup-tools python3 util-linux

# Create a BTRFS volume for mocker
fallocate -l 10G ~/btrfs.img
sudo mkdir /var/mocker
sudo mkfs.btrfs ~/btrfs.img
sudo mount -o loop ~/btrfs.img /var/mocker

# Set up bridge networking
sudo ip link add bridge0 type bridge
sudo ip addr add 10.0.0.1/24 dev bridge0
sudo ip link set bridge0 up
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Install mocker
sudo ln -s "$PWD/mocker" /usr/bin/mocker
sudo chmod +x mocker
```

## Example Usage

```
$ mocker pull centos 7
Authenticating with Docker Hub...
Fetching manifest for centos:7...
Pulling layer sha256:...
Created: img_centos_7

$ mocker images
IMAGE_ID            SOURCE
img_centos_7        centos:7

$ mocker run img_centos_7 cat /etc/centos-release
CentOS Linux release 7.9.2009 (Core)

$ mocker ps
CONTAINER_ID              STATUS    COMMAND
ps_centos_7_045           exited    cat /etc/centos-release

$ mocker logs ps_centos_7_045
CentOS Linux release 7.9.2009 (Core)

$ mocker inspect ps_centos_7_045
=== ps_centos_7_045 ===
Source : n/a
Image  : img_centos_7
Created: 2026-04-12 14:32:01
Command: cat /etc/centos-release
Size   : 248M

$ mocker rm ps_centos_7_045
Removed: ps_centos_7_045

$ mocker run img_centos_7 which wget
which: no wget in (/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin)

$ mocker run img_centos_7 yum install -y wget
Installing : wget-1.14-10.el7_0.1.x86_64                                  1/1
Verifying  : wget-1.14-10.el7_0.1.x86_64                                  1/1
Installed  : wget.x86_64 0:1.14-10.el7_0.1
Complete!

$ mocker commit ps_centos_7_018 img_centos_7
Removed: img_centos_7
Created: img_centos_7

$ mocker run img_centos_7 which wget
/usr/bin/wget

$ mocker tag img_centos_7 img_centos_7_wget
Tagged: img_centos_7 -> img_centos_7_wget

$ mocker images
IMAGE_ID              SOURCE
img_centos_7          centos:7
img_centos_7_wget     centos:7

$ mocker run img_centos_7 cat /proc/1/cgroup
...
4:memory:/ps_centos_7_152
3:cpuacct,cpu:/ps_centos_7_152

$ cat /sys/fs/cgroup/cpu/ps_centos_7_152/cpu.shares
512

$ cat /sys/fs/cgroup/memory/ps_centos_7_152/memory.limit_in_bytes
512000000

# Override resource limits
$ MOCKER_CPU_SHARE=1024 MOCKER_MEM_LIMIT=1024 mocker run img_centos_7 cat /proc/1/cgroup
...
4:memory:/ps_centos_7_188
3:cpuacct,cpu:/ps_centos_7_188

$ cat /sys/fs/cgroup/cpu/ps_centos_7_188/cpu.shares
1024

$ cat /sys/fs/cgroup/memory/ps_centos_7_188/memory.limit_in_bytes
1024000000
```

## Functionality: Currently Implemented

* `docker build` † — via `mocker init <directory>`
* `docker pull` — uses Docker Hub v2 API with Bearer token auth
* `docker images` — via `mocker images`
* `docker ps` — via `mocker ps` (shows running/exited status)
* `docker run` — via `mocker run`
* `docker exec` — via `mocker exec`
* `docker logs` — via `mocker logs`
* `docker commit` — via `mocker commit`
* `docker rm` / `docker rmi` — via `mocker rm`
* `docker inspect` — via `mocker inspect`
* `docker tag` — via `mocker tag`
* Networking (veth pairs, network namespaces, bridge)
* Resource limits (CPU shares and memory caps via cgroups)

† `mocker init` provides a basic implementation of `docker build`

## Functionality: Not Yet Implemented

* Data Volume Containers
* Data Volumes
* Port Forwarding

## How It Works

Mocker uses five Linux kernel primitives — the same ones Docker uses internally:

| Primitive | Purpose |
|---|---|
| **BTRFS subvolumes/snapshots** | Copy-on-write image layering |
| **`unshare`** | Mount, UTS, IPC, and PID namespace isolation |
| **`chroot`** | Filesystem root isolation |
| **cgroups** | CPU and memory resource limits |
| **veth pairs + network namespaces** | Per-container networking |

## License

Copyright (C) 2026 Mohammed OUEDRHIRI

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
