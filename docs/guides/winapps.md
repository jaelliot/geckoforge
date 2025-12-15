# WinApps — Windows Application Integration

## Overview
WinApps enables seamless integration of Windows applications on geckoforge by running Windows in a Docker container and using FreeRDP to render applications as if they were native Linux programs. This allows you to run Microsoft Office, Adobe Creative Cloud, and other Windows-only applications without dual-booting or switching desktops.

## Architecture
WinApps works by:
1. Running Windows 11 in a Docker container with KVM acceleration
2. Automatically downloading Windows ISO from Microsoft servers (legal and automated)
3. Querying Windows for installed applications
4. Creating Linux shortcuts for selected Windows applications
5. Using FreeRDP to render Windows applications seamlessly alongside Linux apps

## Quick Start

### Installation
1. Ensure Docker is configured:
   ```bash
   ./scripts/setup-docker.sh
   ```

2. Run the WinApps setup script:
   ```bash
   ./scripts/setup-winapps.sh
   ```

3. Edit the configuration file:
   ```bash
   nano ~/.config/winapps/winapps.conf
   ```
   Set your desired Windows username and password (used within the VM only).

4. Create the Windows VM:
   ```bash
   winapps-setup
   ```
   Follow the interactive wizard to:
   - Select Windows 11 (downloaded automatically from Microsoft)
   - Configure VM resources (recommend 4-6 CPU cores, 8-16GB RAM, 50GB+ disk)
   - Wait for automated Windows installation (~30-60 minutes)

5. Install Windows applications:
   After Windows boots, install your desired applications (Office, Adobe CC, etc.) inside the Windows VM, then run:
   ```bash
   winapps-setup --install-apps
   ```

### Declarative Configuration (Home-Manager)
Enable WinApps via Home-Manager for reproducible configuration:

```nix
# home/home.nix or custom overlay
programs.winapps = {
  enable = true;
  rdpUser = "WinAppsUser";
  rdpPassword = "YourSecurePassword";
  displayScale = 100;  # 140 or 180 for HiDPI
  backend = "docker";
  
  # Optional: Install system tray launcher
  launcher = true;
  
  # Optional: Auto-pause VM when inactive
  autoPause = {
    enable = true;
    timeout = 300;  # 5 minutes
  };
};
```

Apply changes:
```bash
home-manager switch --flake ~/git/home
```

## Supported Applications
WinApps supports **ALL** Windows applications, including:
- Microsoft Office (Word, Excel, PowerPoint, Outlook, etc.)
- Adobe Creative Cloud (Photoshop, Illustrator, Premiere Pro, etc.)
- Affinity Suite (Designer, Photo, Publisher)
- Visual Studio
- AutoCAD/Fusion 360
- Game engines (Unity, Unreal, GameMaker)
- Any custom Windows executable

Community-tested applications benefit from high-resolution icons and MIME type integration for seamless file opening.

## Configuration Options

### Display Scaling
For high-DPI displays, adjust the scale factor:
```bash
RDP_SCALE="140"  # or 180
```

### Multi-Monitor Support
Add to `RDP_FLAGS` in `winapps.conf`:
```bash
RDP_FLAGS="/cert:tofu /sound /microphone +home-drive /multimon"
```

### Performance Tuning
For better performance, try adding:
```bash
RDP_FLAGS="/cert:tofu /sound /microphone +home-drive /network:lan /gfx"
```

### USB Passthrough
For devices like drawing tablets, microphones, or webcams:
1. Stop WinApps: `winapps stop`
2. Enable experimental USB passthrough in Docker
3. Restart: `winapps start`

See upstream documentation for USB passthrough details.

## File Access
Your Linux `/home` directory is automatically mounted in Windows at:
```
\\tsclient\home
```

Files can be accessed bidirectionally. Nautilus integration allows right-clicking files to open with Windows applications based on MIME types.

## Resource Management

### VM Resource Allocation
Edit during initial setup or later via `winapps-setup --reconfigure`:
- **CPU**: 4-6 cores recommended (don't exceed physical core count)
- **RAM**: 8-16GB recommended for creative applications
- **Disk**: 50GB minimum, 100GB+ for Adobe Creative Cloud

### Auto-Pause
Automatically pause the Windows VM when inactive to save resources:
```bash
AUTOPAUSE="on"
AUTOPAUSE_TIME="300"  # 5 minutes
```

### Manual Control
```bash
winapps start    # Start Windows VM
winapps stop     # Stop Windows VM
winapps restart  # Restart Windows VM
winapps pause    # Pause Windows VM
winapps resume   # Resume Windows VM
```

## WinApps Launcher (Optional)
The WinApps Launcher provides a system tray widget for quick access:
- Launch installed Windows applications
- Control Windows VM (start/stop/pause)
- Open full RDP desktop session
- View VM status at a glance

Install via Home-Manager:
```nix
programs.winapps.launcher = true;
```

Or manually:
```bash
# Via Nix profile
nix profile install github:winapps-org/winapps#winapps-launcher
```

## Running Applications

### From Application Menu
After installation, Windows applications appear in your KDE application menu under "Windows" category.

### From Command Line
```bash
winapps <application-name>
```

### Manual Execution
For applications not configured by the installer:
```bash
winapps manual "C:\Program Files\MyApp\MyApp.exe"
```

### Full Desktop Session
Open a complete Windows desktop:
```bash
winapps windows
```

## Troubleshooting

### FreeRDP Certificate Errors
If you see certificate warnings after VM recreation:
```bash
rm ~/.config/freerdp/server/127.0.0.1_3389.pem
```

### Windows Not Starting
Increase boot timeout in `winapps.conf`:
```bash
BOOT_TIMEOUT="180"
```

### Application Scan Failures
Increase scan timeout:
```bash
APP_SCAN_TIMEOUT="120"
```

### Performance Issues
1. Verify KVM is enabled:
   ```bash
   lscpu | grep Virtualization
   ```
   Should show `AMD-V` or `VT-x`.

2. Check VM resource allocation isn't over-committed
3. Disable window animations in Windows settings
4. Use `/network:lan` flag for better performance

### FreeRDP Version Issues
openSUSE Leap 15.6 may ship older FreeRDP. Check version:
```bash
xfreerdp3 --version
```

If < 3.0, install via Flatpak:
```bash
flatpak install flathub com.freerdp.FreeRDP
sudo flatpak override --filesystem=home com.freerdp.FreeRDP
```

Update `winapps.conf`:
```bash
FREERDP_COMMAND="flatpak run --command=xfreerdp com.freerdp.FreeRDP"
```

### Black Screen on Multi-Monitor
Remove `/multimon` from `RDP_FLAGS` due to FreeRDP bug.

### Applications Won't Launch
1. Ensure Windows VM is running: `winapps start`
2. Check logs: `~/.local/share/winapps/winapps.log`
3. Verify application is installed in Windows
4. Re-run application detection: `winapps-setup --install-apps`

## Updating WinApps
```bash
winapps-setup --update
```

Or via Home-Manager:
```bash
nix flake update ~/git/home
home-manager switch --flake ~/git/home
```

## Security Considerations

### Credential Protection
The `winapps.conf` file contains Windows credentials. Ensure proper permissions:
```bash
chmod 600 ~/.config/winapps/winapps.conf
```

### VM Isolation
The Windows VM is containerized but shares:
- Home directory (via `+home-drive`)
- Removable media
- Network access

Treat the Windows environment as you would your host system regarding:
- Password reuse
- Software downloads
- Network connections

### Malware Risk
If Windows becomes compromised within the VM:
- Files in shared `/home` directory are accessible
- Network access could enable lateral movement
- Consider using a separate user account for sensitive work

## Limitations

### Anti-Cheat Games
Kernel-level anti-cheat systems (Riot Vanguard, EAC, BattlEye) will not work in virtualized environments.

### GPU Acceleration
WinApps uses RemoteApp protocol, which has limited GPU acceleration. For GPU-intensive work:
- Video editing (Premiere, DaVinci Resolve) may be sluggish
- 3D rendering will be slow
- Gaming is not recommended

Consider dual-boot or GPU passthrough solutions for these use cases.

### Performance Overhead
Expect ~10-20% performance penalty compared to native Windows due to:
- Virtualization overhead
- RDP protocol latency
- Network stack traversal

## Advanced Configuration

### Custom Windows ISO
To use a specific Windows ISO instead of auto-download:
```bash
winapps-setup --iso /path/to/windows.iso
```

### Multiple Windows Versions
Run multiple VMs for different Windows versions:
```bash
WAFLAVOR="docker" VM_NAME="Windows10" winapps-setup
WAFLAVOR="docker" VM_NAME="Windows11" winapps-setup
```

### Network Configuration
For advanced networking (static IPs, custom DNS):
```bash
docker network create winapps-net --subnet=172.20.0.0/16
```
Then update Docker run configuration in WinApps.

## Related Resources
- Official WinApps Repository: https://github.com/winapps-org/winapps
- WinApps Launcher: https://github.com/winapps-org/winapps-launcher
- FreeRDP Documentation: https://github.com/FreeRDP/FreeRDP/wiki
- Docker Documentation: https://docs.docker.com/
- geckoforge Docker Setup: [docker-nvidia.md](docker-nvidia.md)

## Use Cases

### Adobe Creative Cloud Workflow
1. Install Adobe Creative Cloud inside Windows VM
2. Sign in with Adobe account
3. Download Photoshop, Illustrator, etc.
4. Access Linux files via `\\tsclient\home`
5. Edit files, save directly to Linux filesystem

### Microsoft Office 365
1. Install Office 365 inside Windows VM
2. Sign in with Microsoft account
3. Use Word, Excel, PowerPoint as native-looking apps
4. Open Office files from Linux file manager via right-click

### Game Development with Unity
1. Install Unity Hub inside Windows VM
2. Create/open Unity projects from `\\tsclient\home\projects`
3. Edit in Unity (Windows), version control from Linux
4. Build Windows executables without dual-boot

### Windows-Only Development Tools
For tools like Visual Studio, SQL Server Management Studio, or legacy corporate applications that must run on Windows.
