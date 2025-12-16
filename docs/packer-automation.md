# Packer Automation for geckoforge Testing

**Date**: December 15, 2025  
**Purpose**: Fully automated VM building with Packer

---

## What is Packer?

HashiCorp Packer automates machine image creation across platforms (VirtualBox, AWS, Azure, etc.). For geckoforge, it can:

✅ **Automate VM creation** - No manual clicking through installer  
✅ **Reproducible builds** - Same VM every time  
✅ **Fast iteration** - Rebuild VM in ~30 minutes  
✅ **Multi-platform** - Build for VirtualBox, VMware, or cloud  
✅ **CI/CD ready** - Integrate with GitHub Actions

---

## Prerequisites

### 1. Install Packer

```bash
# On Ubuntu/WSL2
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Verify
packer version
```

### 2. Install VirtualBox

Already installed for testing.

### 3. Get ISO Checksum

```bash
cd ~/Downloads
sha256sum openSUSE-Leap-15.6-DVD-x86_64-Current.iso

# Copy checksum and update packer/opensuse-leap-geckoforge.pkr.hcl
```

---

## Packer Template Structure

```
geckoforge/
├── packer/
│   ├── opensuse-leap-geckoforge.pkr.hcl  # Main template
│   ├── http/
│   │   └── autoyast.xml                  # Automated install config
│   └── scripts/
│       ├── install-guest-additions.sh
│       └── setup-geckoforge.sh
└── output-virtualbox/                    # Built VM output
    └── geckoforge-test.ova
```

---

## Build VM with Packer

### Basic Build

```bash
cd ~/Documents/Vaidya-Solutions-Code/geckoforge

# Validate template
packer validate packer/opensuse-leap-geckoforge.pkr.hcl

# Build VM
packer build packer/opensuse-leap-geckoforge.pkr.hcl
```

**Build time**: ~30-40 minutes
- Download ISO: ~5 min (if not cached)
- Install openSUSE: ~15 min
- Provisioning: ~10 min
- Export OVA: ~5 min

### Custom Variables

```bash
# Build with custom settings
packer build \
  -var 'memory=16384' \
  -var 'cpus=8' \
  -var 'ssh_username=jay' \
  packer/opensuse-leap-geckoforge.pkr.hcl
```

---

## Import Built VM

```bash
# Import OVA into VirtualBox
VBoxManage import output-virtualbox/geckoforge-test.ova \
  --vsys 0 \
  --vmname "geckoforge-test"

# Or use GUI
# VirtualBox → File → Import Appliance → Select .ova
```

---

## Advanced: Add geckoforge Setup to Build

### Option 1: Bake Into Image

Add to packer template provisioners:

```hcl
# In opensuse-leap-geckoforge.pkr.hcl
provisioner "file" {
  source      = "../"
  destination = "/home/jay/geckoforge"
}

provisioner "shell" {
  inline = [
    "cd /home/jay/geckoforge",
    "./scripts/firstrun-user.sh",
    "cd home",
    "home-manager switch --flake ."
  ]
}
```

**Pros**: VM ready to use immediately  
**Cons**: Slower builds, harder to iterate on configs

### Option 2: Shared Folder (Recommended)

Keep base VM minimal, mount geckoforge as shared folder:

```bash
# After importing VM
VBoxManage sharedfolder add "geckoforge-test" \
  --name "geckoforge" \
  --hostpath "/home/jay/Documents/Vaidya-Solutions-Code/geckoforge" \
  --automount
```

**Pros**: Fast iteration, live updates  
**Cons**: Manual mount setup after build

---

## Automated Testing Pipeline

### 1. Build Base VM (Once)

```bash
packer build packer/opensuse-leap-geckoforge.pkr.hcl
VBoxManage import output-virtualbox/geckoforge-test.ova
```

### 2. Configure Shared Folder

```bash
VBoxManage sharedfolder add "geckoforge-test" \
  --name "geckoforge" \
  --hostpath "$(pwd)" \
  --automount
```

### 3. Start VM + Run Tests

```bash
#!/usr/bin/env bash
# test-automation.sh

VM="geckoforge-test"
SNAPSHOT="base"

# Restore to base snapshot
VBoxManage snapshot "$VM" restore "$SNAPSHOT"

# Start VM (headless)
VBoxManage startvm "$VM" --type headless

# Wait for boot
sleep 60

# SSH and run tests
ssh -p 2222 jay@localhost << 'EOF'
  cd /media/sf_geckoforge
  ./scripts/firstrun-user.sh
  cd home
  home-manager switch --flake .
  
  # Test VS Code
  code --version
  
  # Test languages
  node --version
  python3 --version
  go version
EOF

# Capture exit code
TEST_RESULT=$?

# Shutdown VM
VBoxManage controlvm "$VM" poweroff

# Report
if [ $TEST_RESULT -eq 0 ]; then
  echo "✅ Tests passed"
else
  echo "❌ Tests failed"
  exit 1
fi
```

### 4. CI/CD Integration (GitHub Actions)

```yaml
# .github/workflows/test-vm.yml
name: Test geckoforge VM

on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Packer
        run: |
          curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
          sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
          sudo apt-get update && sudo apt-get install packer
      
      - name: Install VirtualBox
        run: |
          sudo apt-get install -y virtualbox
      
      - name: Build VM
        run: |
          cd packer
          packer build opensuse-leap-geckoforge.pkr.hcl
      
      - name: Test VM
        run: |
          ./test-automation.sh
      
      - name: Upload artifacts
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: test-logs
          path: |
            *.log
            output-virtualbox/
```

---

## Benefits of Packer Approach

### vs. Manual Setup
- ⏱️ **40 min** automated vs. **2 hours** manual
- 🔄 **Reproducible** - same VM every time
- 🤖 **Scriptable** - integrate with CI/CD
- 📦 **Distributable** - export OVA, share with team

### vs. Custom ISO
- ✅ **Works in WSL2** - no kernel restrictions
- ✅ **Faster** - no ISO building step
- ✅ **Official base** - uses openSUSE's tested ISO
- ✅ **Flexible** - easy to customize provisioning

---

## Troubleshooting

### Packer Hangs at Boot

Check boot_wait and boot_command in template. May need adjustment for your ISO version.

### SSH Timeout

```bash
# Increase timeout in template
ssh_timeout = "60m"  # Default is 30m
```

### VirtualBox Guest Additions Fail

```bash
# Ensure kernel-devel installed in autoyast.xml
<package>kernel-devel</package>
<package>gcc</package>
<package>make</package>
```

---

## Next Steps

1. ✅ **Update ISO checksum** in packer template
2. ✅ **Test build**: `packer build packer/opensuse-leap-geckoforge.pkr.hcl`
3. ✅ **Import VM**: `VBoxManage import output-virtualbox/geckoforge-test.ova`
4. ✅ **Add shared folder**: Configure geckoforge repo mount
5. ✅ **Test manually**: Boot VM, run scripts
6. ✅ **Automate**: Use test-automation.sh script
7. ✅ **CI/CD**: Add GitHub Actions workflow

---

## Resources

- **Packer Docs**: https://developer.hashicorp.com/packer/docs
- **VirtualBox Builder**: https://developer.hashicorp.com/packer/plugins/builders/virtualbox
- **AutoYaST Docs**: https://doc.opensuse.org/projects/autoyast/
- **geckoforge Wiki**: ../docs/

---

**Ready to build your first automated VM!** 🚀
