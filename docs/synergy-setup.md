# Synergy Setup Guide

Synergy allows you to share one keyboard and mouse across multiple computers.

---

## Requirements

- **Synergy license** from https://symless.com/synergy
- **Synergy RPM** downloaded from your account

---

## Installation

### 1. Download Synergy

1. Go to https://symless.com/synergy/downloads
2. Log in with your account
3. Download **Linux RPM** file
4. Save to `~/Downloads/`

### 2. Run Setup Script

```bash
cd ~/git/geckoforge
./scripts/setup-synergy.sh
```

The script will:
- Install the Synergy RPM
- Configure firewall ports
- Set up auto-start service
- Launch Synergy for license entry

### 3. Enter License Key

When Synergy launches:
1. Enter your license key
2. Choose client or server mode
3. Configure as prompted

---

## Client Configuration

If this computer will **use** another computer's keyboard/mouse:

1. Script prompts for server IP address
2. Auto-start service is configured
3. Log out and back in
4. Client connects automatically

**Status check:**
```bash
systemctl --user status synergy-client
```

**View logs:**
```bash
journalctl --user -u synergy-client -f
```

---

## Server Configuration

If this computer will **share** its keyboard/mouse:

1. Launch Synergy from app menu
2. Go to Settings → Screen Layout
3. Drag client screens to position
4. Click "Start" to activate server

---

## Firewall

The following ports are opened automatically:
- **24800** - Main Synergy connection
- **24802** - Background service
- **24804** - Background service

**Verify:**
```bash
sudo firewall-cmd --list-ports
```

---

## Troubleshooting

### Connection Issues

**Test server connectivity:**
```bash
ping <server-ip>
telnet <server-ip> 24800
```

**Restart client service:**
```bash
systemctl --user restart synergy-client
```

**Check firewall:**
```bash
sudo firewall-cmd --list-ports
```

### Wayland Issues

Synergy 3 has experimental Wayland support. If you experience issues:

1. Log out
2. Select "Plasma (X11)" session
3. Log back in
4. Try Synergy again

### License Activation

If license won't activate:
1. Check internet connection
2. Verify license key is correct
3. Contact Synergy support: https://symless.com/contact

---

## Alternative: Input Leap

If you don't have a Synergy license, consider **Input Leap** (FOSS alternative):

```bash
flatpak install flathub io.github.input_leap.input-leap
```

Input Leap is free, has better Wayland support, and is compatible with Synergy server configurations.

---

## Resources

- **Synergy Help:** https://help.symless.com/
- **Purchase License:** https://symless.com/synergy
- **Downloads:** https://symless.com/synergy/downloads
- **Support:** https://symless.com/contact