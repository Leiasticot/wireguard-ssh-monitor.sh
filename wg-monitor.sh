#!/bin/bash

################################################################################
#                       🔐 WireGuard Monitoring Script                         #
# This script monitors a WireGuard VPN tunnel and ensures access via SSH in   #
# case of VPN failure. It attempts to restart the VPN and opens a temporary   #
# SSH port if needed. Ideal for VPS where VPN is the only access method.      #
################################################################################

##############################
# 🔧 USER CONFIGURATION AREA #
##############################

WG_INTERFACE="wg0"                            # Name of your WireGuard interface
SSH_PORT="8022"                               # Temporary SSH port to use (avoid using 22)
TMP_RULE_TAG="temp-ssh-backdoor"             # Tag for temporary firewall rule
HANDSHAKE_THRESHOLD=120                       # Max seconds since last handshake before action
ADMIN_EMAIL="your_email@example.com"          # Your email to receive alerts
MSMTP_CONFIG="/home/youruser/.msmtprc"        # Path to your msmtp config file

############################################
# ⚠️ DO NOT MODIFY BELOW UNLESS NEEDED ⚠️  #
############################################

HOSTNAME="$(hostname)"
PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)

# Function to send email using msmtp
send_mail() {
    SUBJECT="$1"
    BODY="$2"
    TO="$ADMIN_EMAIL"

    {
        echo "To: $TO"
        echo "Subject: $SUBJECT"
        echo "From: $ADMIN_EMAIL"
        echo
        echo -e "$BODY"
    } | msmtp --file="$MSMTP_CONFIG" -t
}

# Get time since last handshake
now=$(date +%s)
last_handshake=$(sudo wg show "$WG_INTERFACE" latest-handshakes | awk '{print $2}')

if [[ -z "$last_handshake" || "$last_handshake" -eq 0 ]]; then
    age=$((HANDSHAKE_THRESHOLD + 1))
else
    age=$((now - last_handshake))
fi

if (( age > HANDSHAKE_THRESHOLD )); then
    echo "[WARN] WireGuard tunnel appears inactive..."

    send_mail "⚠️ [VPN Monitor] VPN Down on $HOSTNAME" \
        "🕒 Date: $(date)\n📶 Last handshake: $age seconds ago\n🌍 Public IP: $PUBLIC_IP\n\nAttempting auto-restart..."

    # Restart WireGuard
    sudo systemctl restart wg-quick@$WG_INTERFACE
    sleep 10

    # Check handshake again
    new_handshake=$(sudo wg show "$WG_INTERFACE" latest-handshakes | awk '{print $2}')
    now_after=$(date +%s)
    new_age=$((now_after - new_handshake))

    if [[ -z "$new_handshake" || "$new_age" -gt "$HANDSHAKE_THRESHOLD" ]]; then
        echo "[FAIL] VPN still down after restart"

        # Open temporary SSH port if not already open
        if ! sudo ufw status | grep -q "$TMP_RULE_TAG"; then
            sudo ufw allow "$SSH_PORT"/tcp comment "$TMP_RULE_TAG"
            send_mail "⚠️ [VPN Monitor] Temporary SSH Enabled on $HOSTNAME" \
                "❗ WireGuard is unresponsive after auto-restart.\nTemporary SSH access opened on port $SSH_PORT.\n🌍 Public IP: $PUBLIC_IP\n"
        fi
    else
        echo "[OK] VPN recovered automatically ✅"
        send_mail "✅ [VPN Monitor] VPN Restored on $HOSTNAME" \
            "🎉 WireGuard successfully recovered.\n⏱️ Last handshake: $new_age seconds ago\n🕒 Date: $(date)"
    fi
else
    echo "[OK] VPN is active — checking for any leftover SSH rule..."

    # If VPN is active and SSH rule exists, remove it
    if sudo ufw status numbered | grep -q "$TMP_RULE_TAG"; then
        sudo ufw delete allow "$SSH_PORT"/tcp comment "$TMP_RULE_TAG"
        send_mail "✅ [VPN Monitor] SSH Rule Removed - VPN OK on $HOSTNAME" \
            "🔐 VPN is active again.\nTemporary SSH rule on port $SSH_PORT has been removed.\n🕒 Date: $(date)"
    fi
fi
