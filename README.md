# Network-Scanner

> An interactive, menu-driven network enumeration and host discovery toolkit designed for ethical hacking practice and CTF challenges (Hack The Box, TryHackMe, etc.).

Developed by **[@aryxan](https://github.com/aryxan)**.

---

## ⚠️ Disclaimer
**This tool is created for EDUCATIONAL PURPOSES ONLY.**
Scanning networks or hosts without prior mutual authorization is illegal. The author takes no responsibility for any unauthorized misuse of this software.

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

---

## 🛠️ Requirements

- Linux OS (Kali Linux, Parrot OS, Ubuntu, Debian, etc.)
- `bash` (v4+)
- `nmap`
- `sudo` privileges

---

## 💻 Installation & Usage

```bash
# Clone the repository
git clone https://github.com/aryxan/Network-Scanner.git
cd Network-Scanner

# Make the script executable
chmod +x scanner.sh

# Run the scanner
./scanner.sh
```

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
