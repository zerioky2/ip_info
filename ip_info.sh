#!/usr/bin/env bash
# ip_tracer_force_free.sh
# Usage: sudo ./ip_tracer_force_free.sh <IP_or_hostname>
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <IP_or_hostname>"
  exit 1
fi

TARGET="$1"
OUT="/tmp/ip_info_${TARGET//./_}_$(date +%s).txt"
: > "$OUT"
echo " ============================================== " | tee -a "$OUT"
echo " ==================== INFO  IP ================ " | tee -a "$OUT"
echo " ============================================== " | tee -a "$OUT"
echo "\"IP Address    > $TARGET" | tee -a "$OUT"
echo "\"Date & Time   > $(date --iso-8601=seconds)" | tee -a "$OUT"
echo " ============================================== " | tee -a "$OUT"

#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <IP>"
  exit 1
fi

IP="$1"

# Utilisation de l'API pour obtenir des informations géographiques
API_URL="http://ip-api.com/json/$IP"
RESPONSE=$(curl -s "$API_URL")

# Extraire les informations
CITY=$(echo "$RESPONSE" | jq -r '.city')
COUNTRY=$(echo "$RESPONSE" | jq -r '.country')
ZIP=$(echo "$RESPONSE" | jq -r '.zip')
LAT=$(echo "$RESPONSE" | jq -r '.lat')
LON=$(echo "$RESPONSE" | jq -r '.lon')

# Afficher les résultats
echo "Informations géographiques $IP :"
echo " ============================================== " | tee -a "$OUT"
echo "Ville        : $CITY"
echo "Pays        : $COUNTRY"
echo "Code postal  : $ZIP"
echo "Latitude     : $LAT"
echo "Longitude    : $LON"

# Resolve to IP if hostname (single block only)
IP="$TARGET"
if ! [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  IP="$(dig +short A "$TARGET" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1 || echo "$TARGET")"
fi
#echo "\"Resolved IP   > ${IP:-N/A}" | tee -a "$OUT"
echo " ============================================== " | tee -a "$OUT"
echo " Fournisseur " | tee -a "$OUT"
echo " ============================================== " | tee -a "$OUT"
# PTR, A, AAAA
PTR="$(dig +short -x "$IP" | sed 's/\.$//' || true)"; [ -z "$PTR" ] && PTR="N/A"
A_REC="$(dig +short A "$TARGET" | paste -s -d',' -)"; [ -z "$A_REC" ] && A_REC="N/A"
AAAA_REC="$(dig +short AAAA "$TARGET" | paste -s -d',' -)"; [ -z "$AAAA_REC" ] && AAAA_REC="N/A"
echo "\"PTR / Host    > $PTR" | tee -a "$OUT"
#echo "\"A record      > $A_REC" | tee -a "$OUT"
#echo "\"AAAA record   > $AAAA_REC" | tee -a "$OUT"

WHOIS_RAW="$(whois "$IP" 2>/dev/null || true)"
WHOIS_SUM="$(echo "$WHOIS_RAW" | sed -n '1,160p' | tr '\n' ' ' )"; [ -z "$WHOIS_SUM" ] && WHOIS_SUM="N/A"

# Extract useful fields
ROUTE_LINE="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /^(route|route6):/ {sub(/^.*: */,""); print; exit}')"
DESCR_LINE="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /^(descr|netname):/ {sub(/^.*: */,""); print; exit}')"
ORIGIN_LINE="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /^(origin|originas):/ {sub(/^.*: */,""); print; exit}')"

ROUTE_LINE=${ROUTE_LINE:-N/A}
DESCR_LINE=${DESCR_LINE:-N/A}
ORIGIN_LINE=${ORIGIN_LINE:-N/A}

# Force show "Free SAS" if present in any of those lines
ISP_DISPLAY="N/A"
if echo "$DESCR_LINE $ROUTE_LINE $ORIGIN_LINE $WHOIS_RAW" | grep -qi 'free sas\|free\s\|proxad'; then
  if echo "$WHOIS_RAW" | grep -qi 'descr:.*free sas'; then
    ISP_DISPLAY="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /descr:/ && tolower($0) ~ /free sas/ {sub(/^.*: */,""); print; exit}')"
  elif echo "$WHOIS_RAW" | grep -qi 'descr:.*free'; then
    ISP_DISPLAY="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /descr:/ && tolower($0) ~ /free/ {sub(/^.*: */,""); print; exit}')"
  elif echo "$WHOIS_RAW" | grep -qi 'route:.*free'; then
    ISP_DISPLAY="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /route:/ && tolower($0) ~ /free/ {sub(/^.*: */,""); print; exit}')"
  else
    ISP_DISPLAY="$(echo "$WHOIS_RAW" | grep -Eio 'free sas|free' | head -n1 || true)"
  fi
fi

if [ -z "$ISP_DISPLAY" ] || [ "$ISP_DISPLAY" = "N/A" ]; then
  if [ "$DESCR_LINE" != "N/A" ]; then ISP_DISPLAY="$DESCR_LINE"; fi
fi
if [ -z "$ISP_DISPLAY" ] || [ "$ISP_DISPLAY" = "N/A" ]; then
  if [ "$ROUTE_LINE" != "N/A" ]; then ISP_DISPLAY="$ROUTE_LINE"; fi
fi
if [ -z "$ISP_DISPLAY" ] || [ "$ISP_DISPLAY" = "N/A" ]; then
  if [ "$ORIGIN_LINE" != "N/A" ]; then ISP_DISPLAY="$ORIGIN_LINE"; fi
fi
ISP_DISPLAY=${ISP_DISPLAY:-N/A}

echo "\"ISP / ASN     > ${ORIGIN_LINE:-N/A}" | tee -a "$OUT"
echo "\"Organization  > $ISP_DISPLAY" | tee -a "$OUT"

# Admin org
ORG_HANDLE="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /(^| )org:/{print $2; exit}' | tr -d '\r')"
if [ -n "$ORG_HANDLE" ]; then
  ORG_NAME="$(whois -h whois.ripe.net "$ORG_HANDLE" 2>/dev/null | awk 'BEGIN{IGNORECASE=1} /org-name:|org-name /{sub(/^.*: */,""); print; exit}')"
else
  ORG_NAME="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /org-name:|orgname:|organisation:/{sub(/^.*: */,""); print; exit}')"
fi
ORG_NAME=${ORG_NAME:-N/A}
echo "\"Org (admin)   > $ORG_NAME" | tee -a "$OUT"

# Normalize abuse
ABUSE="$(echo "$WHOIS_RAW" | awk 'BEGIN{IGNORECASE=1} /abuse-mailbox:|abuse-c:|abuse:/{sub(/^.*: */,""); print; exit}')"
if [ -z "$ABUSE" ]; then
  ABUSE="$(echo "$WHOIS_RAW" | grep -Eio '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | grep -i abuse | head -n1 || true)"
fi
ABUSE=${ABUSE:-N/A}
echo "\"Abuse contact > $ABUSE" | tee -a "$OUT"

echo " ============================================== " | tee -a "$OUT"
echo " VPN OU TOR ? " | tee -a "$OUT"
echo " ============================================== " | tee -a "$OUT"

# --- VPN / Datacenter heuristic detection ---
VPN_FLAG="no"
VPN_REASON="N/A"
ORIG_LC="$(echo "${ORIGIN_LINE} ${ISP_DISPLAY} ${WHOIS_RAW}" | tr '[:upper:]' '[:lower:]')"
DC_KEYWORDS="amazon|aws|google|google cloud|digitalocean|hetzner|ovh|ovhcloud|scaleway|linode|azure|microsoft|vultr|cloudflare|rackspace|ibm|softlayer|do\.spaces"
VPN_KEYWORDS="nordvpn|protonvpn|mullvad|pia|private internet access|expressvpn|surfshark|hide my ass|hidemyass|windscribe|vpn|vpnbook|torguard|proxd|proxad"

if echo "$ORIG_LC" | grep -Eq "$DC_KEYWORDS"; then
  VPN_FLAG="yes"
  VPN_REASON="datacenter/org match"
elif echo "$ORIG_LC" | grep -Eq "$VPN_KEYWORDS"; then
  VPN_FLAG="yes"
  VPN_REASON="vpn provider match"
else
  ASN="$(echo "$ORIGIN_LINE" | grep -Eo 'AS[0-9]+' | tr -d '\r' || true)"
  case "${ASN:-}" in
    AS16509|AS14618|AS14061|AS16276|AS12876|AS12874|AS8553)
      VPN_FLAG="yes"
      VPN_REASON="asn match"
      ;;
  esac
fi

if [ "$VPN_FLAG" = "yes" ]; then
  echo "\"VPN_PROBABLE  > yes ($VPN_REASON)" | tee -a "$OUT"
else
  echo "\"VPN_PROBABLE  > no" | tee -a "$OUT"
fi

# --- Tor exit node detection ---
IS_TOR="no"
TOR_REASON="N/A"
reverse_ip() { local ip="$1"; echo "$ip" | awk -F. '{print $4"."$3"."$2"."$1}'; }

if command -v dig >/dev/null 2>&1; then
  REV="$(reverse_ip "$IP")"
  if dig +short "${REV}.dnsel.torproject.org" A 2>/dev/null | grep -q '[0-9]'; then
    IS_TOR="yes"
    TOR_REASON="TorDNSEL listed"
  else
    if dig +short "${REV}.exitlist.torproject.org" A 2>/dev/null | grep -q '[0-9]'; then
      IS_TOR="yes"
      TOR_REASON="exitlist listed"
    fi
  fi
fi

if [ "$IS_TOR" = "no" ] && [ -f /etc/tor_exit_nodes.txt ]; then
  if grep -qx "$IP" /etc/tor_exit_nodes.txt; then
    IS_TOR="yes"
    TOR_REASON="local list"
  fi
fi

echo "\"Tor Exit Node  > ${IS_TOR} (${TOR_REASON})" | tee -a "$OUT"

# final output file display (optional)
# cat "$OUT"
# Scanner les ports ouverts
#echo " ============================================== " | tee -a "$OUT"
#echo " Scan des ports ouverts pour $IP : " | tee -a "$OUT"
#echo " ============================================== " | tee -a "$OUT"
#nmap --open -p 1-65535 "$IP"



# Traceroute
#echo " ============================================== " | tee -a "$OUT"
#echo " Traceroute vers $IP : " | tee -a "$OUT"
#echo " ============================================== " | tee -a "$OUT"
#traceroute "$IP" | tee -a "$OUT" 

