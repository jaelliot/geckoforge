# Thunderbird Email Client Setup

**Status:** Production Ready  
**Layer:** 4 (Home-Manager) + 3 (User Setup for ProtonMail)  
**Security Posture:** Hardened (Anti-Phishing)

---

## Overview

Geckoforge includes Mozilla Thunderbird as the default email client with hardened security settings to prevent phishing attacks. Links in emails are **not clickable** by default—you must manually copy and paste URLs to verify them before opening.

## Security Configuration

### Anti-Phishing Measures

- ✅ **Clickable links disabled** - Prevents accidental clicks on phishing URLs
- ✅ **Remote content blocked** - No tracking pixels or external images
- ✅ **Plain text preference** - HTML rendering minimized
- ✅ **Telemetry disabled** - No data sent to Mozilla
- ✅ **JavaScript disabled** - Reduces attack surface

### Workflow with Disabled Links

When you receive an email with a link:

1. **Right-click** the link text → **Copy Link Location**
2. **Inspect the URL** in a text editor or terminal
3. **Verify legitimacy** (check domain, look for typos)
4. **Paste into browser** if safe

**Example:**
```bash
# Inspect URL safely
echo "https://example.com/suspicious-link?track=abc123" | grep -E "^https://[a-zA-Z0-9.-]+\.[a-z]{2,}/"
```

---

## Email Provider Setup

### Gmail

**IMAP Configuration:**
- Server: `imap.gmail.com`
- Port: `993`
- Security: `SSL/TLS`
- Authentication: `OAuth2` (recommended) or App Password

**SMTP Configuration:**
- Server: `smtp.gmail.com`
- Port: `587`
- Security: `STARTTLS`
- Authentication: `OAuth2` (recommended) or App Password

**Prerequisites:**
1. Enable IMAP: [Gmail Settings](https://mail.google.com/mail/u/0/#settings/fwdandpop)
2. **Option A (Recommended):** Use OAuth2 (Thunderbird will prompt)
3. **Option B:** Generate App Password:
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Enable 2FA if not already enabled
   - Generate App Password under "Signing in to Google"
   - Use this password in Thunderbird

---

### Outlook / Office 365

**IMAP Configuration:**
- Server: `outlook.office365.com`
- Port: `993`
- Security: `SSL/TLS`
- Authentication: `OAuth2` (recommended)

**SMTP Configuration:**
- Server: `smtp.office365.com`
- Port: `587`
- Security: `STARTTLS`
- Authentication: `OAuth2` (recommended)

**Prerequisites:**
1. Thunderbird 78+ supports OAuth2 for Outlook automatically
2. When adding account, select "OAuth2" as authentication method
3. Browser window will open for Microsoft login
4. Authorize Thunderbird to access your mailbox

**Troubleshooting:**
- If OAuth2 not offered, update Thunderbird: `sudo zypper update MozillaThunderbird`
- Check [Microsoft's IMAP settings](https://support.microsoft.com/en-us/office/pop-imap-and-smtp-settings-8361e398-8af4-4e97-b147-6c6c4ac95353)

---

### ProtonMail (Requires Bridge)

ProtonMail uses end-to-end encryption, requiring **ProtonMail Bridge** to work with Thunderbird.

#### Step 1: Install ProtonMail Bridge

Run the setup script:
```bash
cd ~/git/geckoforge
./scripts/setup-protonmail-bridge.sh
```

Choose installation method:
1. **Flatpak** (recommended - sandboxed)
2. **Official RPM** from [proton.me/mail/bridge](https://proton.me/mail/bridge)

#### Step 2: Configure ProtonMail Bridge

Start Bridge:
```bash
protonmail-bridge --cli
```

Or launch from application menu: **ProtonMail Bridge**

In Bridge interface:
1. Click **Sign In** and enter ProtonMail credentials
2. Enable 2FA if prompted
3. Bridge will display **IMAP** and **SMTP** credentials
4. **Copy these credentials** (needed for Thunderbird)

#### Step 3: Add Account to Thunderbird

**IMAP Configuration:**
- Server: `127.0.0.1`
- Port: `1143`
- Security: `STARTTLS`
- Username: From Bridge (usually your ProtonMail address)
- Password: From Bridge (generated password, NOT your ProtonMail password)

**SMTP Configuration:**
- Server: `127.0.0.1`
- Port: `1025`
- Security: `STARTTLS`
- Username: From Bridge
- Password: From Bridge

**Auto-Start Bridge:**
```bash
# Enable systemd service
systemctl --user enable protonmail-bridge.service
systemctl --user start protonmail-bridge.service

# Check status
systemctl --user status protonmail-bridge.service
```

---

## Adding Accounts to Thunderbird

### Manual Configuration

1. Open Thunderbird
2. **File** → **New** → **Existing Mail Account**
3. Enter:
   - Name: Your display name
   - Email: Your email address
   - Password: (Provider-specific)
4. Click **Continue**
5. If auto-detect fails, click **Manual Configuration**
6. Enter server settings from provider section above
7. Click **Re-test** → **Done**

### OAuth2 Authentication

For Gmail and Outlook:
1. Select **OAuth2** as authentication method
2. Thunderbird will open browser for login
3. Authorize Thunderbird
4. Return to Thunderbird (should auto-complete)

---

## Reverting Security Settings

If you need to enable clickable links temporarily:

### Via Config Editor

1. Open Thunderbird
2. **Settings** → **Advanced** → **Config Editor**
3. Search: `network.protocol-handler.external-default`
4. Double-click to toggle `false` → `true`
5. Restart Thunderbird

### Via Home-Manager

Edit `~/git/geckoforge/home/home.nix`:
```nix
programs.thunderbird-hardened = {
  enable = true;
  disableLinks = false;  # <-- Change to false
  # ... other settings ...
};
```

Rebuild:
```bash
home-manager switch --flake ~/git/geckoforge/home
```

---

## Troubleshooting

### Links Won't Copy

**Issue:** Right-click → Copy Link Location is grayed out

**Solution:** The text isn't recognized as a URL. Manually select and copy the text.

### Remote Content Needed

**Issue:** Legitimate email looks broken without images

**Solution:** Click **Load Remote Content** button at top of message (per-message basis)

### Plain Text Too Restrictive

**Issue:** Need to view HTML email occasionally

**Solution:** **View** → **Message Body As** → **Original HTML**

### ProtonMail Bridge Not Starting

**Check service:**
```bash
systemctl --user status protonmail-bridge.service
journalctl --user -u protonmail-bridge.service -f
```

**Restart manually:**
```bash
systemctl --user restart protonmail-bridge.service
```

**Check ports:**
```bash
ss -tlnp | grep -E ':(1143|1025)'
```

### Account Login Fails

**Gmail/Outlook OAuth2:**
- Clear browser cache and cookies
- Try "Sign in with Google/Microsoft" again
- Check [Google App Passwords](https://myaccount.google.com/apppasswords)

**ProtonMail Bridge:**
- Verify Bridge is running: `systemctl --user status protonmail-bridge`
- Check Bridge credentials match Thunderbird
- Bridge password is NOT your ProtonMail password

---

## Additional Security Recommendations

### GPG/PGP Encryption

1. Generate key: `gpg --full-generate-key`
2. In Thunderbird: **Account Settings** → **End-to-End Encryption**
3. Import or generate OpenPGP key
4. Exchange public keys with contacts

### S/MIME Certificates

1. Obtain certificate from CA (e.g., Comodo, DigiCert)
2. **Account Settings** → **End-to-End Encryption** → **S/MIME**
3. Import certificate

### Spam Filtering

- **Tools** → **Message Filters** for custom rules
- Mark spam to train junk filter
- Use **Search Folders** to organize

---

## References

- [Thunderbird Support](https://support.mozilla.org/en-US/products/thunderbird)
- [Gmail IMAP Settings](https://support.google.com/mail/answer/7126229)
- [Outlook IMAP Settings](https://support.microsoft.com/en-us/office/pop-imap-and-smtp-settings-8361e398-8af4-4e97-b147-6c6c4ac95353)
- [ProtonMail Bridge Documentation](https://proton.me/support/protonmail-bridge-install)
- [OpenPGP in Thunderbird](https://support.mozilla.org/en-US/kb/openpgp-thunderbird-howto-and-faq)

---

**Geckoforge Project**  
Email Security Configuration  
Rev. 2025-10-11