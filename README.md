# Network-Scanner

> An interactive, menu-driven network enumeration and host discovery toolkit designed for ethical hacking practice and CTF challenges (Hack The Box, TryHackMe, etc.).

Developed by **[@aryxan](https://github.com/aryxan)**.

---

## ⚠️ Disclaimer
**This tool is created for EDUCATIONAL PURPOSES ONLY.**
Scanning networks or hosts without prior mutual written authorization is illegal. The author takes no responsibility for any unauthorized misuse or damage caused by this software. Use strictly in authorized lab environments, CTF challenges, or networks you own.

---

## 🧠 Prerequisite Knowledge

To understand how this tool functions and to interpret the results effectively, users should be familiar with:

1. **Networking Fundamentals**:
   - **IPv4 & CIDR Notation**: Understanding subnets (e.g., `/24` = 256 IPs), network/broadcast addresses, and subnet masks.
   - **Network Protocols**:
     - **ARP (Address Resolution Protocol)**: Layer 2 communication used in local subnets. Recognizing how Nmap uses ARP requests (`who-has`) for local ping sweeps.
     - **ICMP (Internet Control Message Protocol)**: Echo Requests (Type 8) and Echo Replies (Type 0). Understanding why firewalls drop ICMP packets and how TTL (Time-to-Live) values hint at the target operating system (e.g., TTL ~64 for Linux, TTL ~128 for Windows).
     - **TCP/UDP Protocols**: Handshake mechanisms and common service ports (e.g., SSH:22, HTTP:80, SMB:445).
   - **Network Routing & Interfaces**: Understanding local interfaces (`eth0`, `wlan0`, `lo`) versus virtual VPN tunnels (`tun0`, `tap0`) used in lab environments like Hack The Box and TryHackMe.

2. **Nmap Scanning Techniques**:
   - **Ping Sweeps (`-sn`)**: Host discovery without port scanning to identify alive targets quickly.
   - **Packet Tracing (`--packet-trace`)**: Observing raw packets sent and received at each stage of a scan.
   - **Scan Reasoning (`--reason`)**: Determining *why* Nmap classified a host or port as open, closed, filtered, or alive (e.g. `received arp-response`, `received echo-reply`).
   - **Bypassing ARP Pings (`--disable-arp-ping`)**: Forcing ICMP requests instead of ARP when troubleshooting or diagnosing host responses.
   - **Aggressive Scanning (`-A`)**: Combining OS detection (`-O`), service version detection (`-sV`), script scanning (`-sC`), and traceroute (`--traceroute`).

3. **Linux Command-Line & Permissions**:
   - Understanding standard file paths, bash scripting, and execution permissions (`chmod +x`).
   - Managing root and `sudo` privileges required to send raw packets and inspect `/etc/shadow`.

---

## 🛠️ Pre-installed Tools & Dependencies

Ensure the following tools are installed on your Linux system before running the script:

| Tool / Package | Command | Required For |
| :--- | :--- | :--- |
| **Nmap** | `nmap` | Core network scanning, ping sweeps, and service enumeration |
| **Bash** (v4.0+) | `bash` | Script runtime, associative logic, and UI rendering |
| **IPRoute2** | `ip` | Auto-detecting active network interfaces (VPN/Ethernet) and subnets |
| **Core Utilities** | `grep`, `cut`, `sort`, `sed`, `printf`, `cat`, `wc` | Text processing, pipeline parsing, and table formatting |
| **Python 3** | `python3` | Secure root shadow verification for workspace file inspection |
| **Sudo** | `sudo` | Executing privileged raw network socket scans |

### Quick Installation Command

#### On Debian / Ubuntu / Kali Linux / Parrot OS:
```bash
sudo apt update && sudo apt install -y nmap iproute2 coreutils python3 sudo bash
```

#### On Arch Linux:
```bash
sudo pacman -Syu --needed nmap iproute2 coreutils python sudo bash
```

#### On Fedora / RHEL:
```bash
sudo dnf install -y nmap iproute coreutils python3 sudo bash
```

---

## 🚀 Features

- **Interactive Workspace Management**: Create unique session folders or open existing workspaces without overwriting previous scan logs.
- **Root Password Protection**: Protects inspection of sensitive workspace logs and findings behind root/sudo authentication.
- **Auto-Detection**: Automatically identifies local network interfaces and VPN tunnels (e.g. `tun0`, `tun1` for HTB / THM).
- **Multiple Discovery Modes**:
  1. **Subnet / Network Sweep**: Scans whole CIDRs (e.g., `10.129.2.0/24`) and extracts live hosts.
  2. **Multiple IPs / Range**: Supports octet ranges (`10.129.2.18-20`) or multiple discrete IPs.
  3. **Target List**: Read targets from files (`-iL`).
  4. **Single IP Diagnostics**:
     - Standard Host Discovery (`-sn -oA host`)
     - ICMP Echo Ping + Packet Trace (`-PE --packet-trace`)
     - ICMP Echo Ping + Reason (`-PE --reason`)
     - Disable ARP Ping + ICMP + Packet Trace (`-PE --packet-trace --disable-arp-ping`)
  5. **Aggressive OS & Service Detection**: Full OS fingerprinting, version detection, traceroute, and script scans (`sudo nmap -A <target>`).
- **Target Selection**: Easily select targets by typing the IP or simply choosing their index from the live hosts list.
- **Clean Uniform Terminal UI**: Pixel-perfect box borders and clean categorized menus.

---

## 💻 Installation & Usage

```bash
# 1. Clone the repository
git clone https://github.com/aryxan/Network-Scanner.git
cd Network-Scanner

# 2. Make the script executable
chmod +x scanner.sh

# 3. Run the scanner
./scanner.sh
```

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
