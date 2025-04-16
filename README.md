# 🔐 WireGuard Monitoring Script with Temporary SSH Fallback

> **Disclaimer:** This script was created by a beginner (helped with chatgpt) still learning the ropes. It is provided as-is and may not be fully reliable or exhaustive in all scenarios. Feedback, improvements, or forks are more than welcome!

This Bash script is designed to continuously monitor the status of a **WireGuard** VPN interface (`wg0`) and provide a temporary SSH global access fallback in case of VPN failure, by opening the SSH port to public ip.

I'm a bit paranoid and can't find a solution in case my wireguard connexion stop since it's my only way to connect to my VPS and I don't want to always expose my SSH port so I made this script
Default SSH port is 8022 because you shouldn't use port 22.

---

## 🚀 Key Features

- ⏱️ **VPN Health Check**: Detects missing handshakes with a configurable threshold (default: 120 seconds).
- 🔁 **Auto-Restart**: Attempts to restart the WireGuard service if no handshake is detected.
- 📬 **Email Notifications**: Sends alert emails via `msmtp` in cases of:
  - VPN disconnection,
  - Automatic recovery,
  - Temporary SSH access being enabled or disabled.
- 🛡️ **Temporary SSH Access**: Automatically opens a backup SSH port (default: `8022`) via UFW if WireGuard cannot be restarted.
- ✅ **Auto-Cleanup**: Closes the temporary SSH port once the VPN is confirmed to be operational again.

---

## ⚙️ Requirements

- WireGuard installed and configured on interface `wg0`
- Active `ufw` firewall for port management
- `msmtp` configured for sending emails (via `~/.msmtprc` or other location)
- `sudo` access to restart services and modify firewall rules

---

## 📌 Customizable Variables

The following script variables can be adjusted to suit your environment:

```bash
WG_INTERFACE="wg0"              # WireGuard interface name
SSH_PORT="8022"                 # Temporary SSH access port
HANDSHAKE_THRESHOLD=120         # Max age (in seconds) since last handshake
ADMIN_EMAIL="MAIL@DOMAIN"  # Notification email address
MSMTP_CONFIG="/home/user/.msmtprc"  # Path to msmtp config
```

---

## 📥 Usage Example

Make the script executable:
```bash
chmod +x /path/to/wg-monitor.sh
```
Schedule this script via cron to ensure regular VPN monitoring, e.g. every 5 minutes:

```bash
*/5 * * * * /path/to/wg-monitor.sh
```

---

## 🧪 Manual Test

You can manually test the script's behavior by stopping the WireGuard interface:

```bash
sudo systemctl stop wg-quick@wg0
```
Then run the script and verify:
- An alert email is sent
- Temporary SSH port is opened
- VPN tunnel is restarted automatically

---

## 📄 License & Notice

This script is provided without any warranty. Use it at your own risk and adapt it to your needs. It is meant as a personal learning project and may benefit from further review or contributions.

---
