#!/bin/sh
# Usage: sh /root/check-block.sh AA:BB:CC:DD:EE:FF 192.168.1.50
MAC="$1"
IP="$2"

if [ -z "$MAC" ] || [ -z "$IP" ]; then
  echo "Usage: $0 <MAC> <IP>"
  exit 1
fi

echo "=== Router date/time ==="
date
echo

echo "=== iptables FORWARD (first 200 lines) ==="
iptables -L FORWARD -n -v --line-numbers | sed -n '1,200p'
echo

echo "=== iptables rules that mention the MAC (${MAC}) ==="
iptables-save | grep -i --color=never "$MAC" || echo "No iptables-save entries matching $MAC"
echo

echo "=== ip6tables FORWARD (IPv6) ==="
if command -v ip6tables >/dev/null 2>&1; then
  ip6tables -L FORWARD -n -v --line-numbers | sed -n '1,200p'
else
  echo "ip6tables not available"
fi
echo

echo "=== ip6tables rules that mention the MAC (${MAC}) ==="
if command -v ip6tables-save >/dev/null 2>&1; then
  ip6tables-save | grep -i --color=never "$MAC" || echo "No ip6tables-save entries matching $MAC"
else
  echo "ip6tables-save not available"
fi
echo

echo "=== conntrack entries for IP (${IP}) ==="
if command -v conntrack >/dev/null 2>&1; then
  conntrack -L | grep --color=never "$IP" || echo "No conntrack entries for $IP"
else
  echo "conntrack not installed (install with: opkg update && opkg install conntrack)"
fi
echo

echo "=== AccessControl config (/etc/config/accesscontrol) ==="
if [ -f /etc/config/accesscontrol ]; then
  sed -n '1,200p' /etc/config/accesscontrol
else
  echo "/etc/config/accesscontrol not present"
fi
echo

echo "=== UCI firewall config (relevant rules shown) ==="
uci show firewall | sed -n '1,200p' | grep -i -E "name|src_mac|src|dest|target|family" || echo "No firewall uci output"
echo

echo "=== Recent system log (last 80 lines) ==="
logread | tail -n 80
echo

echo "=== Next checks and tips ==="
echo "- Look for FORWARD rule matching --mac-source and REJECT/DROP."
echo "- If IPv6 rules are missing, IPv6 can bypass the block."
echo "- If conntrack entries exist, remove them to drop sessions: conntrack -D -s ${IP}"
echo "- If time is wrong, adjust timezone/NTP (date shows current time)."
