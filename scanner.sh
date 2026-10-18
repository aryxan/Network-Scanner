#!/usr/bin/env bash

# ==============================================================================
# Ethical Hacking Network Scanner
# Interactive, Clean & Modern CLI for Network Enumeration (HTB / CTF)
# ==============================================================================

set -o pipefail

# Base directory for all scans
SCANS_BASE_DIR="./scans"

# Terminal Colors & Styling
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
# Author Information
AUTHOR="aryxan"
GITHUB_URL="https://github.com/aryxan"

# ------------------------------------------------------------------------------
# UI Helpers: Dynamic Uniform Box Alignment
# ------------------------------------------------------------------------------
print_box_row() {
    local text="$1"
    local color="${2:-$CYAN}"
    local width="${3:-56}"
    # Strip ANSI escape codes to calculate visual character length
    local plain
    plain=$(echo -e "$text" | sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g")
    local len=${#plain}
    local pad=$((width - len))
    [ $pad -lt 0 ] && pad=0
    local spaces
    spaces=$(printf "%*s" "$pad" "")
    echo -e "${color}│${NC} ${text}${spaces} ${color}│${NC}"
}

print_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  _   _      _     ____                                  
 | \ | | ___| |_  / ___|  ___ __ _ _ __  _ __   ___ _ __ 
 |  \| |/ _ \ __| \___ \ / __/ _` | '_ \| '_ \ / _ \ '__|
 | |\  |  __/ |_   ___) | (_| (_| | | | | | | |  __/ |   
 |_| \_|\___|\__| |____/ \___\__,_|_| |_|_| |_|\___|_|   
EOF
    echo -e "${DIM}       [ Network Enumeration & Host Discovery Toolkit ]${NC}"
    echo -e "       ${DIM}Author:${NC} ${CYAN}${BOLD}$AUTHOR${NC} ${DIM}| GitHub:${NC} ${DIM}$GITHUB_URL${NC}"
    echo ""
}

# ------------------------------------------------------------------------------
# Educational Disclaimer & User Agreement
# ------------------------------------------------------------------------------
show_disclaimer_and_prompt() {
    clear
    print_banner
    echo -e "${YELLOW}┌──[ DISCLAIMER & WARNING - EDUCATIONAL PURPOSES ONLY ]────┐${NC}"
    print_box_row "${BOLD}WARNING:${NC} This tool is strictly for educational and" "$YELLOW" 56
    print_box_row "authorized security auditing/practice purposes only." "$YELLOW" 56
    print_box_row "" "$YELLOW" 56
    print_box_row "Scanning targets or networks without authorization is" "$YELLOW" 56
    print_box_row "illegal. The author assumes no liability for misuse." "$YELLOW" 56
    print_box_row "" "$YELLOW" 56
    print_box_row "${CYAN}Author :${NC} ${BOLD}$AUTHOR${NC}" "$YELLOW" 56
    print_box_row "${CYAN}GitHub :${NC} ${DIM}$GITHUB_URL${NC}" "$YELLOW" 56
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""

    if [ -t 0 ]; then
        read -rp "$(echo -e "${YELLOW}[?] Do you agree to use this tool for Educational Purposes only? [y/N]: ${NC}")" confirm
        case "$confirm" in
            [yY]|[yY][eE][sS])
                echo -e "\n${GREEN}[✓] Agreement confirmed. Launching scanner...${NC}\n"
                sleep 0.8
                ;;
            *)
                echo -e "\n${RED}[✗] You must agree to the educational terms to use this tool. Exiting.${NC}\n"
                exit 1
                ;;
        esac
    fi
}

print_section() {
    local title="$1"
    echo -e "\n${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    print_box_row "${BOLD}$title${NC}" "$CYAN" 56
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
}

print_cmd_box() {
    local cmd="$1"
    echo -e "\n${BLUE}┌──[ Executing Command ]${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}$cmd${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────${NC}\n"
}

# ------------------------------------------------------------------------------
# Function: Auto-detect local network CIDR or target IP
# ------------------------------------------------------------------------------
detect_target() {
    local detected=""

    # 1. Check for VPN interface first (tun0, tun1, tap0 common in HTB / THM)
    for iface in tun0 tun1 tap0; do
        if ip link show "$iface" >/dev/null 2>&1; then
            detected=$(ip -o -f inet addr show "$iface" 2>/dev/null | awk '{print $4}' | head -n1)
            if [ -n "$detected" ]; then
                echo "$detected"
                return
            fi
        fi
    done

    # 2. Check default route interface
    local def_iface
    def_iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5}' | head -n1)
    if [ -n "$def_iface" ]; then
        detected=$(ip -o -f inet addr show "$def_iface" 2>/dev/null | awk '{print $4}' | head -n1)
        if [ -n "$detected" ]; then
            echo "$detected"
            return
        fi
    fi

    # 3. Fallback: first non-loopback active interface
    detected=$(ip -o -f inet addr show 2>/dev/null | awk '$2 != "lo" {print $4}' | head -n1)
    echo "$detected"
}

# ------------------------------------------------------------------------------
# Function: Verify Root Password
# ------------------------------------------------------------------------------
verify_root_password() {
    local max_attempts=3
    local attempt=1

    echo -e "${YELLOW}┌──[ Authentication Required ]${NC}"
    echo -e "${YELLOW}│  Root password is required to inspect workspace files.${NC}"
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────${NC}"

    while [ $attempt -le $max_attempts ]; do
        read -rsp "$(echo -e "${CYAN}[?] Enter root password (attempt $attempt/$max_attempts): ${NC}")" root_pass
        echo ""

        if [ -z "$root_pass" ]; then
            echo -e "${RED}[✗] Password cannot be empty.${NC}"
            ((attempt++))
            continue
        fi

        local auth_success=false

        # 1. Check shadow if readable (e.g. running under sudo or as root)
        if [ -r /etc/shadow ]; then
            if python3 -c '
import sys, crypt
try:
    with open("/etc/shadow") as f:
        for line in f:
            parts = line.strip().split(":")
            if parts[0] == "root":
                root_hash = parts[1]
                if root_hash in ("*", "!", ""):
                    sys.exit(2)
                pw = sys.argv[1]
                if crypt.crypt(pw, root_hash) == root_hash:
                    sys.exit(0)
                else:
                    sys.exit(1)
    sys.exit(2)
except Exception:
    sys.exit(2)
' "$root_pass" 2>/dev/null; then
                auth_success=true
            fi
        fi

        # 2. Try su - root
        if [ "$auth_success" = false ]; then
            if echo "$root_pass" | su - root -c "true" 2>/dev/null; then
                auth_success=true
            fi
        fi

        # 3. Try sudo verification
        if [ "$auth_success" = false ]; then
            if echo "$root_pass" | sudo -S -k -v 2>/dev/null; then
                auth_success=true
            fi
        fi

        if [ "$auth_success" = true ]; then
            echo -e "${GREEN}[✓] Authentication successful! Access granted.${NC}"
            return 0
        fi

        echo -e "${RED}[✗] Authentication failed. Incorrect password.${NC}"
        ((attempt++))
    done

    echo -e "${RED}[✗] Access denied: Too many failed attempts.${NC}"
    return 1
}

# ------------------------------------------------------------------------------
# Function: Show Workspace Files (Protected by Root Password)
# ------------------------------------------------------------------------------
show_workspace_files() {
    print_section "WORKSPACE FINDINGS & LOGS"
    echo -e "Target Directory: ${BOLD}$SCAN_DIR${NC}\n"

    # Require Root Password
    if ! verify_root_password; then
        return
    fi

    echo -e "\n${CYAN}┌──[ File Listing ]───────────────────────────────────────────┐${NC}"
    ls -lah "$SCAN_DIR" | while IFS= read -r line; do
        echo -e "${CYAN}│${NC} $line"
    done
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"

    if [ -s "$LIVE_HOSTS_FILE" ]; then
        echo -e "\n${GREEN}┌──[ Discovered Live Hosts ]──────────────────────────────────┐${NC}"
        cat -n "$LIVE_HOSTS_FILE" | while IFS= read -r host; do
            echo -e "${GREEN}│${NC} $host"
        done
        echo -e "${GREEN}└─────────────────────────────────────────────────────────────┘${NC}"
    fi

    local nmap_count
    nmap_count=$(find "$SCAN_DIR" -maxdepth 1 -name "*.nmap" 2>/dev/null | wc -l)
    if [ "$nmap_count" -gt 0 ]; then
        echo -e "\n${BLUE}┌──[ Scan Reports ($nmap_count total) ]──────────────────────────────┐${NC}"
        for report in "$SCAN_DIR"/*.nmap; do
            if [ -f "$report" ]; then
                local lines
                lines=$(wc -l < "$report")
                printf "${BLUE}│${NC} %-35s ${DIM}(%4d lines)${NC}\n" "$(basename "$report")" "$lines"
            fi
        done
        echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
    fi
}

# ------------------------------------------------------------------------------
# Helper: Display Live Hosts for Selection
# ------------------------------------------------------------------------------
display_live_hosts() {
    if [ -s "$LIVE_HOSTS_FILE" ]; then
        echo -e "${CYAN}┌──[ Discovered Live Hosts in Workspace ]${NC}"
        cat -n "$LIVE_HOSTS_FILE" | while IFS= read -r host; do
            echo -e "${CYAN}│${NC} $host"
        done
        echo -e "${CYAN}└──────────────────────────────────────────────────────────────${NC}"
        echo -e "${DIM}Tip: Enter IP directly or type list number [1, 2, ...]${NC}\n"
    fi
}

# ------------------------------------------------------------------------------
# Helper: Resolve Input Target (Supports index number or IP)
# ------------------------------------------------------------------------------
resolve_target_ip() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]+$ ]] && [ -s "$LIVE_HOSTS_FILE" ]; then
        local found
        found=$(sed -n "${input}p" "$LIVE_HOSTS_FILE")
        if [ -n "$found" ]; then
            echo "$found"
            return
        fi
    fi
    echo "$input"
}

# ------------------------------------------------------------------------------
# Function: Create New Workspace
# ------------------------------------------------------------------------------
create_new_workspace() {
    local default_name="scan_$(date +%Y%m%d_%H%M%S)"
    local scan_name=""

    print_section "CREATE NEW WORKSPACE"
    if [ -t 0 ]; then
        read -rp "$(echo -e "${YELLOW}[?] Workspace name [default: ${BOLD}$default_name${NC}${YELLOW}]: ${NC}")" input_name
        scan_name="${input_name:-$default_name}"
    else
        scan_name="${SCAN_NAME:-$default_name}"
    fi

    # Clean name
    scan_name=$(echo "$scan_name" | sed -e 's/[^a-zA-Z0-9._-]/_/g')

    local base_path="$SCANS_BASE_DIR/$scan_name"
    local dir_path="$base_path"
    local counter=1

    while [ -d "$dir_path" ]; do
        dir_path="${base_path}_${counter}"
        ((counter++))
    done

    mkdir -p "$dir_path"
    SCAN_DIR="$dir_path"
    LIVE_HOSTS_FILE="$SCAN_DIR/live_hosts.txt"

    echo -e "\n${GREEN}[✓] Workspace initialized: ${BOLD}$SCAN_DIR${NC}"
}

# ------------------------------------------------------------------------------
# Function: Open Existing Workspace
# ------------------------------------------------------------------------------
open_existing_workspace() {
    print_section "OPEN EXISTING WORKSPACE"
    local workspaces=()

    while IFS= read -r dir; do
        [ -n "$dir" ] && workspaces+=("$dir")
    done < <(find "$SCANS_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort)

    if [ ${#workspaces[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] No existing workspaces found. Creating a new one instead...${NC}"
        create_new_workspace
        return
    fi

    echo -e "${CYAN}Available Workspaces:${NC}"
    for i in "${!workspaces[@]}"; do
        local ws_path="$SCANS_BASE_DIR/${workspaces[$i]}"
        local file_count
        file_count=$(find "$ws_path" -maxdepth 1 -type f 2>/dev/null | wc -l)
        printf "  ${CYAN}[%2d]${NC} %-30s ${DIM}(%d files)${NC}\n" "$((i+1))" "${workspaces[$i]}" "$file_count"
    done
    echo ""

    local sel=""
    while true; do
        read -rp "$(echo -e "${YELLOW}[?] Select workspace [1-${#workspaces[@]}]: ${NC}")" sel
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le "${#workspaces[@]}" ]; then
            local chosen="${workspaces[$((sel-1))]}"
            SCAN_DIR="$SCANS_BASE_DIR/$chosen"
            LIVE_HOSTS_FILE="$SCAN_DIR/live_hosts.txt"
            echo -e "\n${GREEN}[✓] Active workspace switched to: ${BOLD}$SCAN_DIR${NC}"
            break
        else
            echo -e "${RED}[✗] Invalid number. Please choose 1 to ${#workspaces[@]}.${NC}"
        fi
    done

    echo ""
    read -rp "$(echo -e "${YELLOW}[?] View workspace files now? (requires root password) [Y/n]: ${NC}")" view_ans
    case "$view_ans" in
        [nN]|[nN][oO])
            ;;
        *)
            show_workspace_files
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Function: Setup / Select Workspace
# ------------------------------------------------------------------------------
setup_scan_directory() {
    mkdir -p "$SCANS_BASE_DIR"

    local count
    count=$(find "$SCANS_BASE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        print_section "WORKSPACE SETUP"
        echo -e "  ${CYAN}[1]${NC} Create a new workspace"
        echo -e "  ${CYAN}[2]${NC} Open an existing workspace ${DIM}(${count} available)${NC}"
        echo ""
        read -rp "$(echo -e "${YELLOW}[?] Choose option [1-2, default: 1]: ${NC}")" ws_choice
        ws_choice="${ws_choice:-1}"

        if [ "$ws_choice" = "2" ]; then
            open_existing_workspace
            return
        fi
    fi

    create_new_workspace
}

# ------------------------------------------------------------------------------
# Option 1: Scan Network / Subnet
# ------------------------------------------------------------------------------
menu_scan_subnet() {
    print_section "OPTION 1: SCAN NETWORK / SUBNET"

    local auto_target
    auto_target=$(detect_target)

    local target=""
    if [ -n "$auto_target" ]; then
        read -rp "$(echo -e "${YELLOW}[?] Enter target CIDR [default: ${BOLD}$auto_target${NC}${YELLOW}]: ${NC}")" input_target
        target="${input_target:-$auto_target}"
    else
        read -rp "$(echo -e "${YELLOW}[?] Enter target CIDR (e.g. 10.129.2.0/24): ${NC}")" target
    fi

    if [ -z "$target" ]; then
        echo -e "${RED}[✗] Error: Target cannot be empty.${NC}"
        return
    fi

    local out_prefix="$SCAN_DIR/tnet"
    print_cmd_box "sudo nmap $target -sn -oA $out_prefix | grep for | cut -d' ' -f5"

    sudo nmap "$target" -sn -oA "$out_prefix" | grep for | cut -d" " -f5 | tee -a "$LIVE_HOSTS_FILE"

    if [ -f "$LIVE_HOSTS_FILE" ]; then
        sort -u "$LIVE_HOSTS_FILE" -o "$LIVE_HOSTS_FILE"
    fi

    echo -e "\n${GREEN}[✓] Discovered hosts saved to: ${BOLD}$LIVE_HOSTS_FILE${NC}"
    echo -e "${GREEN}[✓] Full reports saved to:    ${BOLD}${out_prefix}.*${NC}"
}

# ------------------------------------------------------------------------------
# Option 2: Scan Multiple IPs or IP Range
# ------------------------------------------------------------------------------
menu_scan_multiple_ips() {
    print_section "OPTION 2: SCAN MULTIPLE IPS / RANGE"
    echo -e "${DIM}Supported Formats:${NC}"
    echo -e "  • Range:    ${CYAN}10.129.2.18-20${NC}"
    echo -e "  • Discrete: ${CYAN}10.129.2.18 10.129.2.19 10.129.2.20${NC}\n"

    read -rp "$(echo -e "${YELLOW}[?] Enter IPs or range: ${NC}")" targets

    if [ -z "$targets" ]; then
        echo -e "${RED}[✗] Error: No targets specified.${NC}"
        return
    fi

    local out_prefix="$SCAN_DIR/tnet_multiple"
    print_cmd_box "sudo nmap -sn -oA $out_prefix $targets | grep for | cut -d' ' -f5"

    # shellcheck disable=SC2086
    sudo nmap -sn -oA "$out_prefix" $targets | grep for | cut -d" " -f5 | tee -a "$LIVE_HOSTS_FILE"

    if [ -f "$LIVE_HOSTS_FILE" ]; then
        sort -u "$LIVE_HOSTS_FILE" -o "$LIVE_HOSTS_FILE"
    fi

    echo -e "\n${GREEN}[✓] Discovered hosts saved to: ${BOLD}$LIVE_HOSTS_FILE${NC}"
    echo -e "${GREEN}[✓] Full reports saved to:    ${BOLD}${out_prefix}.*${NC}"
}

# ------------------------------------------------------------------------------
# Option 3: Scan from File List (-iL)
# ------------------------------------------------------------------------------
menu_scan_list() {
    print_section "OPTION 3: SCAN TARGETS FROM FILE (-iL)"

    local list_path=""
    while true; do
        read -rp "$(echo -e "${YELLOW}[?] Path to targets file (or 'b' to back): ${NC}")" list_path
        if [ "$list_path" = "b" ] || [ "$list_path" = "B" ]; then
            return
        fi
        list_path="${list_path/#\~/$HOME}"
        if [ -f "$list_path" ]; then
            break
        else
            echo -e "${RED}[✗] File '$list_path' not found. Please try again.${NC}"
        fi
    done

    local out_prefix="$SCAN_DIR/tnet_list"
    print_cmd_box "sudo nmap -sn -oA $out_prefix -iL $list_path | grep for | cut -d' ' -f5"

    sudo nmap -sn -oA "$out_prefix" -iL "$list_path" | grep for | cut -d" " -f5 | tee -a "$LIVE_HOSTS_FILE"

    if [ -f "$LIVE_HOSTS_FILE" ]; then
        sort -u "$LIVE_HOSTS_FILE" -o "$LIVE_HOSTS_FILE"
    fi

    echo -e "\n${GREEN}[✓] Discovered hosts saved to: ${BOLD}$LIVE_HOSTS_FILE${NC}"
    echo -e "${GREEN}[✓] Full reports saved to:    ${BOLD}${out_prefix}.*${NC}"
}

# ------------------------------------------------------------------------------
# Option 4: Scan Single IP
# ------------------------------------------------------------------------------
menu_scan_single_ip() {
    print_section "OPTION 4: SCAN SINGLE IP (HOST DISCOVERY)"

    display_live_hosts

    read -rp "$(echo -e "${YELLOW}[?] Enter target IP (or list number): ${NC}")" input_target
    if [ -z "$input_target" ]; then
        echo -e "${RED}[✗] Error: Target IP cannot be empty.${NC}"
        return
    fi

    local target_ip
    target_ip=$(resolve_target_ip "$input_target")
    echo -e "${GREEN}[*] Target Selected: ${BOLD}$target_ip${NC}\n"

    local clean_ip
    clean_ip=$(echo "$target_ip" | tr -s '.:/' '_')
    local out_prefix="$SCAN_DIR/host_${clean_ip}"

    echo -e "${BOLD}Select Scan Technique:${NC}"
    echo -e "  ${CYAN}[1]${NC} Standard Host Discovery               ${DIM}(-sn -oA host)${NC}"
    echo -e "  ${CYAN}[2]${NC} ICMP Echo + Packet Trace              ${DIM}(-sn -oA host -PE --packet-trace)${NC}"
    echo -e "  ${CYAN}[3]${NC} ICMP Echo + Reason                    ${DIM}(-sn -oA host -PE --reason)${NC}"
    echo -e "  ${CYAN}[4]${NC} Disable ARP Ping + ICMP + Trace       ${DIM}(-sn -oA host -PE --packet-trace --disable-arp-ping)${NC}"
    echo -e "  ${CYAN}[b]${NC} Back to Main Menu"
    echo ""
    read -rp "$(echo -e "${YELLOW}[?] Choose technique [1-4, default: 1]: ${NC}")" mode_choice
    mode_choice="${mode_choice:-1}"

    case "$mode_choice" in
        1)
            print_cmd_box "sudo nmap $target_ip -sn -oA $out_prefix"
            sudo nmap "$target_ip" -sn -oA "$out_prefix"
            ;;
        2)
            print_cmd_box "sudo nmap $target_ip -sn -oA $out_prefix -PE --packet-trace"
            sudo nmap "$target_ip" -sn -oA "$out_prefix" -PE --packet-trace
            ;;
        3)
            print_cmd_box "sudo nmap $target_ip -sn -oA $out_prefix -PE --reason"
            sudo nmap "$target_ip" -sn -oA "$out_prefix" -PE --reason
            ;;
        4)
            print_cmd_box "sudo nmap $target_ip -sn -oA $out_prefix -PE --packet-trace --disable-arp-ping"
            sudo nmap "$target_ip" -sn -oA "$out_prefix" -PE --packet-trace --disable-arp-ping
            ;;
        [bB])
            return
            ;;
        *)
            print_cmd_box "sudo nmap $target_ip -sn -oA $out_prefix"
            sudo nmap "$target_ip" -sn -oA "$out_prefix"
            ;;
    esac

    echo -e "\n${GREEN}[✓] Scan output stored in: ${BOLD}${out_prefix}.*${NC}"
}

# ------------------------------------------------------------------------------
# Option 5: Detailed OS & Service Details Scan (-A)
# ------------------------------------------------------------------------------
menu_scan_os_details() {
    print_section "OPTION 5: DETAILED OS & SERVICE SCAN (-A)"

    display_live_hosts

    read -rp "$(echo -e "${YELLOW}[?] Enter target IP (e.g. 192.168.29.74 or list number): ${NC}")" input_target
    if [ -z "$input_target" ]; then
        echo -e "${RED}[✗] Error: Target IP cannot be empty.${NC}"
        return
    fi

    local target_ip
    target_ip=$(resolve_target_ip "$input_target")
    echo -e "${GREEN}[*] Target Selected: ${BOLD}$target_ip${NC}\n"

    local clean_ip
    clean_ip=$(echo "$target_ip" | tr -s '.:/' '_')
    local out_prefix="$SCAN_DIR/os_details_${clean_ip}"

    print_cmd_box "sudo nmap -A $target_ip -oA $out_prefix"
    sudo nmap -A "$target_ip" -oA "$out_prefix"

    echo -e "\n${GREEN}[✓] Detailed OS findings stored in: ${BOLD}${out_prefix}.*${NC}"
}

# ------------------------------------------------------------------------------
# Option 6: View Saved Findings (Requires Root Password)
# ------------------------------------------------------------------------------
menu_view_findings() {
    show_workspace_files
}

# ------------------------------------------------------------------------------
# Main Menu Loop
# ------------------------------------------------------------------------------
main_menu() {
    while true; do
        clear
        print_banner

        # Workspace & Environment Status Bar
        local host_count=0
        if [ -s "$LIVE_HOSTS_FILE" ]; then
            host_count=$(wc -l < "$LIVE_HOSTS_FILE")
        fi

        local detected_net
        detected_net=$(detect_target)
        [ -z "$detected_net" ] && detected_net="None detected"

        echo -e "${CYAN}┌──[ Session Overview ]────────────────────────────────────┐${NC}"
        print_box_row "${BOLD}Workspace     :${NC} ${GREEN}$(basename "$SCAN_DIR")${NC}" "$CYAN" 56
        print_box_row "${BOLD}Directory     :${NC} $SCAN_DIR" "$CYAN" 56
        print_box_row "${BOLD}Local Network :${NC} ${YELLOW}$detected_net${NC}" "$CYAN" 56
        print_box_row "${BOLD}Live Hosts    :${NC} ${MAGENTA}$host_count discovered${NC}" "$CYAN" 56
        echo -e "${CYAN}├──────────────────────────────────────────────────────────┤${NC}"
        print_box_row "${BOLD}HOST DISCOVERY${NC}" "$CYAN" 56
        print_box_row " ${CYAN}[1]${NC} Scan Subnet / Network" "$CYAN" 56
        print_box_row " ${CYAN}[2]${NC} Scan Multiple IPs / Range" "$CYAN" 56
        print_box_row " ${CYAN}[3]${NC} Scan Targets from File" "$CYAN" 56
        print_box_row "" "$CYAN" 56
        print_box_row "${BOLD}TARGET ENUMERATION${NC}" "$CYAN" 56
        print_box_row " ${CYAN}[4]${NC} Scan Single IP" "$CYAN" 56
        print_box_row " ${CYAN}[5]${NC} Detailed OS & Service Scan" "$CYAN" 56
        print_box_row "" "$CYAN" 56
        print_box_row "${BOLD}WORKSPACE & CONTROLS${NC}" "$CYAN" 56
        print_box_row " ${CYAN}[6]${NC} View Workspace Files" "$CYAN" 56
        print_box_row " ${CYAN}[7]${NC} Create or Switch Workspace" "$CYAN" 56
        print_box_row " ${CYAN}[0]${NC} Exit" "$CYAN" 56
        echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
        echo ""

        read -rp "$(echo -e "${YELLOW}[?] Select an option [0-7]: ${NC}")" opt

        case "$opt" in
            1) menu_scan_subnet ;;
            2) menu_scan_multiple_ips ;;
            3) menu_scan_list ;;
            4) menu_scan_single_ip ;;
            5) menu_scan_os_details ;;
            6) menu_view_findings ;;
            7) setup_scan_directory ;;
            0|[qQ])
                echo -e "\n${GREEN}[✓] Happy Hacking! Exiting...${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}[✗] Invalid option. Please select 0-7.${NC}"
                ;;
        esac

        echo ""
        read -rp "$(echo -e "${DIM}Press [Enter] to return to the menu...${NC}")" _
    done
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
main() {
    show_disclaimer_and_prompt
    setup_scan_directory
    main_menu
}

main "$@"
