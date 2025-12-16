# Packer Build for geckoforge

Automated VM image builder that creates a complete geckoforge environment.

## What Gets Built

The Packer template creates a VirtualBox OVA with:

- ✅ openSUSE Leap 15.6 (NET ISO - minimal install)
- ✅ KDE Plasma desktop
- ✅ VirtualBox Guest Additions
- ✅ Docker + NVIDIA Container Toolkit
- ✅ Nix (multi-user) + Home-Manager
- ✅ VS Code with 29 extensions pre-configured
- ✅ Development tools: Python, Node.js, Go, Elixir, R, .NET, TeX
- ✅ All geckoforge scripts and configurations
- ✅ Btrfs filesystem with Snapper (snapshots)
- ✅ EFI boot + Secure Boot ready

## Prerequisites

### Install Packer

```bash
# Ubuntu/Debian/WSL2
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Verify
packer version
```

### Install VirtualBox

```bash
# Ubuntu/Debian
sudo apt-get install virtualbox

# Verify
VBoxManage --version
```

## Quick Start

```bash
# From project root
cd packer

# Run build script
./build.sh
```

Build takes **45-60 minutes** and produces `output-virtualbox/geckoforge-test.ova`

## Manual Build

```bash
cd packer

# Validate template
packer validate opensuse-leap-geckoforge.pkr.hcl

# Build
packer build opensuse-leap-geckoforge.pkr.hcl
```

### Build Options

```bash
# Custom RAM/CPUs
packer build \
  -var 'memory=16384' \
  -var 'cpus=8' \
  opensuse-leap-geckoforge.pkr.hcl

# Custom username
packer build \
  -var 'ssh_username=myuser' \
  -var 'ssh_password=mypassword' \
  opensuse-leap-geckoforge.pkr.hcl
```

## Import Built Image

### CLI

```bash
VBoxManage import output-virtualbox/geckoforge-test.ova \
  --vsys 0 \
  --vmname "geckoforge-complete"
```

### GUI

1. VirtualBox → **File** → **Import Appliance**
2. Select `output-virtualbox/geckoforge-test.ova`
3. Click **Import**

## First Boot

1. **Start VM**
2. **Login**: `jay` / `vagrant` (default)
3. **Desktop shortcut**: Double-click "Complete geckoforge Setup"
4. **Follow prompts** to finalize configuration
5. **Reboot** when complete

Everything is pre-installed, just needs final activation!

## What's Where

```
/opt/geckoforge/           # Geckoforge repository
  scripts/                 # Setup scripts
  home/                    # Home-Manager configs
  docs/                    # Documentation

~/.config/                 # KDE/app configs
~/.local/                  # User applications
/nix/                      # Nix package store

/etc/geckoforge-version    # Build version marker
```

## Customization

### Modify Software Selection

Edit `http/autoyast.xml`:

```xml
<packages config:type="list">
  <package>your-package</package>
</packages>
```

### Modify Provisioning

Edit `opensuse-leap-geckoforge.pkr.hcl`:

```hcl
provisioner "shell" {
  inline = [
    "your-command"
  ]
}
```

### Skip Geckoforge Setup

Remove provisioners #6-9 to build just the base system.

## Troubleshooting

### Build Fails at AutoYaST Stage

- **Issue**: Network timeout during package download
- **Fix**: Check internet connection, retry build

### VirtualBox Guest Additions Fail

- **Issue**: Kernel headers mismatch
- **Fix**: Ensure `kernel-devel` package in AutoYaST

### Nix Installation Fails

- **Issue**: Insufficient disk space
- **Fix**: Increase `disk_size` variable

### Home-Manager Fails

- **Issue**: First-time activation issues
- **Fix**: Complete setup runs on first boot via desktop shortcut

## Advanced

### Build for Different Platforms

Packer supports multiple builders. To add VMware support:

```hcl
source "vmware-iso" "opensuse" {
  # VMware-specific configuration
}

build {
  sources = [
    "source.virtualbox-iso.opensuse_leap",
    "source.vmware-iso.opensuse"
  ]
  # ... provisioners
}
```

### Continuous Integration

Use in GitHub Actions:

```yaml
- name: Install Packer
  run: |
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install packer

- name: Build Image
  run: |
    cd packer
    packer build opensuse-leap-geckoforge.pkr.hcl

- name: Upload Artifact
  uses: actions/upload-artifact@v3
  with:
    name: geckoforge-ova
    path: packer/output-virtualbox/*.ova
```

## Files

- `opensuse-leap-geckoforge.pkr.hcl` - Main Packer template
- `http/autoyast.xml` - Automated installation config
- `build.sh` - Automated build script
- `README.md` - This file

## Resources

- [Packer Documentation](https://www.packer.io/docs)
- [VirtualBox Builder](https://www.packer.io/plugins/builders/virtualbox)
- [AutoYaST Guide](https://doc.opensuse.org/projects/autoyast/)
- [geckoforge Documentation](../docs/)

---

**Build time:** ~45-60 minutes  
**Output size:** ~8-10GB OVA  
**Result:** Fully configured development workstation ready to use!
