# 🔐 WireGuard Monitoring Script with Temporary SSH Fallback

> **Disclaimer:** This script was created by a beginner (with a little help from ChatGPT) still learning the ropes. It is provided *as-is* and may not be fully reliable or exhaustive in all scenarios. Feedback, improvements, or forks are more than welcome!

This Bash script continuously monitors the status of a **WireGuard** VPN interface (`wg0`) and provides a temporary SSH global access fallback in case of VPN failure by opening the SSH port to the public via UFW.

I'm a bit paranoid and couldn't find a clean solution in case my VPN dies — it's my only way to access my VPS. I also don’t want to expose SSH permanently, so I wrote this script.

PS: Default SSH port is `8022` — because **you really shouldn't use port 22**.

---

## ❓ Should *you* use this script?

Not sure if this is for you? Ask yourself:

1. 🤔 **Do I have a VPS or remote server with no physical access?**  
   - If yes → continue.  
   - If no → you’re probably fine, move along.

2. 🔐 **Is WireGuard my *only* way to connect via SSH?**  
   - If yes → keep going.  
   - If not → you might not need this, but it's still cool.

3. 🔥 **Am I using UFW as my firewall?**  
   - If yes → perfect, carry on.  
   - If not → you'll need to adapt the script for your firewall.

4. 📧 **Can I send emails from my server using `msmtp`?**  
   - If yes → you're good to go.  
   - If not → set it up or disable email alerts in the script.

Still here? Great. This script is for you.

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

All key settings can be found at the top of the script for easy tweaking:

```bash
WG_INTERFACE="wg0"                            # WireGuard interface name
SSH_PORT="8022"                               # Temporary SSH port to open
TMP_RULE_TAG="temp-ssh-backdoor"             # UFW rule tag for identification
HANDSHAKE_THRESHOLD=120                       # Seconds since last handshake before triggering recovery
ADMIN_EMAIL="your_email@example.com"          # Where to send alerts
MSMTP_CONFIG="/home/youruser/.msmtprc"        # Path to msmtp config file
```

---

## 📥 Usage Example

### 1. Make the script executable:

```bash
chmod +x /path/to/wg-monitor.sh
```

### 2. Set up a cron job to run it every 5 minutes:

```bash
*/5 * * * * /path/to/wg-monitor.sh >> /path/to/logs/wg-monitor.log 2>&1
```

### 3. (Optional but recommended) Add a log rotation rule:

```bash
sudo nano /etc/logrotate.d/wg-monitor
```

Paste this (adjust path as needed):

```
/path/to/logs/wg-monitor.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
```

---

## 🧪 Manual Test

You can manually test the script by stopping WireGuard:

```bash
sudo systemctl stop wg-quick@wg0
```

Then run the script:

```bash
/path/to/wg-monitor.sh
```

You should see:
- An email alert
- Temporary SSH port opened via UFW
- WireGuard restarted

---

## 📄 License & Notice

This script is provided without any warranty. Use it at your own risk and adapt it to your needs.  
It’s a personal project, a learning experience, and a little peace of mind.

---
