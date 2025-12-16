# Packer template for geckoforge testing VM
# Automates openSUSE Leap 15.6 + geckoforge setup

packer {
  required_version = ">= 1.9.0"
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Current.iso"
  description = "NET ISO - only 180MB, downloads packages during install"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:f0ee6281392c894b3a68262893d3d0bbfed9dc34d3e56c2df7a13d5b4c9c1a66"
  description = "Checksum for NET ISO - verify at download.opensuse.org"
}

variable "vm_name" {
  type    = string
  default = "geckoforge-test"
}

variable "disk_size" {
  type    = number
  default = 51200 # 50GB in MB
}

variable "memory" {
  type    = number
  default = 8192 # 8GB
}

variable "cpus" {
  type    = number
  default = 4
}

variable "ssh_username" {
  type    = string
  default = "jay"
}

variable "ssh_password" {
  type      = string
  default   = "vagrant"
  sensitive = true
}

source "virtualbox-iso" "opensuse_leap" {
  vm_name              = var.vm_name
  guest_os_type        = "OpenSUSE_64"
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  
  # Hardware
  disk_size            = var.disk_size
  hard_drive_interface = "sata"
  memory               = var.memory
  cpus                 = var.cpus
  
  # EFI Boot
  iso_interface        = "sata"
  firmware             = "efi"
  
  # Network
  guest_additions_mode = "upload"
  guest_additions_path = "/tmp/VBoxGuestAdditions.iso"
  
  # SSH for provisioning
  ssh_username         = var.ssh_username
  ssh_password         = var.ssh_password
  ssh_timeout          = "30m"
  
  # Boot command for automated install
  boot_wait = "10s"
  boot_command = [
    "<esc><wait>",
    "linux netdevice=eth0 netsetup=dhcp install=cd:/ ",
    "lang=en_US autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/autoyast.xml ",
    "<enter>"
  ]
  
  # Serve autoyast file
  http_directory = "packer/http"
  
  # Shutdown
  shutdown_command = "echo '${var.ssh_password}' | sudo -S shutdown -P now"
  
  # VirtualBox settings
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--vram", "128"],
    ["modifyvm", "{{.Name}}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{.Name}}", "--audio", "none"],
  ]
  
  # Output
  output_directory = "output-virtualbox"
  format           = "ova"
}

build {
  sources = ["source.virtualbox-iso.opensuse_leap"]
  
  # 1. Wait for system to boot
  provisioner "shell" {
    inline = [
      "echo 'System booted successfully'",
      "sleep 5"
    ]
  }
  
  # 2. Install VirtualBox Guest Additions
  provisioner "shell" {
    inline = [
      "sudo zypper --non-interactive install -y kernel-devel gcc make perl",
      "sudo mkdir -p /mnt/vbox",
      "sudo mount -o loop /tmp/VBoxGuestAdditions.iso /mnt/vbox",
      "sudo sh /mnt/vbox/VBoxLinuxAdditions.run || true",
      "sudo umount /mnt/vbox",
      "sudo rm -f /tmp/VBoxGuestAdditions.iso"
    ]
  }
  
  # 3. Update system
  provisioner "shell" {
    inline = [
      "sudo zypper --non-interactive refresh",
      "sudo zypper --non-interactive update -y"
    ]
  }
  
  # 4. Install git
  provisioner "shell" {
    inline = [
      "sudo zypper --non-interactive install -y git"
    ]
  }
  
  # 5. Copy geckoforge repo into image
  provisioner "file" {
    source      = "../"
    destination = "/tmp/geckoforge"
  }
  
  provisioner "shell" {
    inline = [
      "sudo mv /tmp/geckoforge /opt/geckoforge",
      "sudo chown -R ${var.ssh_username}:users /opt/geckoforge",
      "sudo chmod +x /opt/geckoforge/scripts/*.sh"
    ]
  }
  
  # 6. Run geckoforge first-run setup
  provisioner "shell" {
    inline = [
      "cd /opt/geckoforge",
      "# Install Docker",
      "sudo zypper --non-interactive install -y docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ${var.ssh_username}",
      "",
      "# Install Nix (multi-user)",
      "sh <(curl -L https://nixos.org/nix/install) --daemon --yes || true",
      "",
      "# Source Nix environment",
      "if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then",
      "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh",
      "fi",
      "",
      "# Install Home-Manager",
      "nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz home-manager || true",
      "nix-channel --update || true",
      "nix-shell '<home-manager>' -A install || true"
    ]
  }
  
  # 7. Apply Home-Manager configuration (bake in all packages)
  provisioner "shell" {
    environment_vars = [
      "NIX_PATH=/nix/var/nix/profiles/per-user/${var.ssh_username}/channels"
    ]
    inline = [
      "# Source Nix",
      "if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then",
      "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh",
      "fi",
      "",
      "# Apply Home-Manager config",
      "cd /opt/geckoforge/home",
      "home-manager switch --flake . || echo 'Home-Manager will be configured on first boot'",
      "",
      "# Create desktop shortcut for easy access",
      "mkdir -p /home/${var.ssh_username}/Desktop",
      "cat > /home/${var.ssh_username}/Desktop/geckoforge-setup.desktop << 'EOF'",
      "[Desktop Entry]",
      "Type=Application",
      "Name=Complete geckoforge Setup",
      "Exec=/opt/geckoforge/scripts/firstrun-user.sh",
      "Icon=utilities-terminal",
      "Terminal=true",
      "EOF",
      "chmod +x /home/${var.ssh_username}/Desktop/geckoforge-setup.desktop"
    ]
  }
  
  # 8. Install NVIDIA container toolkit (will detect GPU on real hardware)
  provisioner "shell" {
    inline = [
      "cd /opt/geckoforge",
      "./scripts/docker-nvidia-install.sh || echo 'NVIDIA setup will run on GPU hardware'"
    ]
  }
  
  # 9. Clean up and optimize
  provisioner "shell" {
    inline = [
      "# Clean package cache",
      "sudo zypper clean --all",
      "",
      "# Clean temporary files",
      "sudo rm -rf /tmp/*",
      "",
      "# Create version marker",
      "echo 'geckoforge-complete-${formatdate("YYYY-MM-DD-hhmm", timestamp())}' | sudo tee /etc/geckoforge-version",
      "",
      "# Create README on desktop",
      "cat > /home/${var.ssh_username}/Desktop/README.txt << 'EOF'",
      "geckoforge Complete Environment",
      "===============================",
      "",
      "This VM has everything pre-configured:",
      "✓ openSUSE Leap 15.6 + KDE Plasma",
      "✓ Docker installed",
      "✓ Nix + Home-Manager",
      "✓ VS Code with 29 extensions",
      "✓ Development tools (Python, Node, Go, Elixir, etc.)",
      "",
      "First Boot:",
      "1. Double-click 'Complete geckoforge Setup' on desktop",
      "2. Follow prompts to finalize configuration",
      "3. Reboot when complete",
      "",
      "Repository: /opt/geckoforge",
      "Documentation: /opt/geckoforge/docs/",
      "",
      "Enjoy!",
      "EOF"
    ]
  }
  
  # Post-processor: Create OVA
  post-processor "manifest" {
    output = "manifest.json"
  }
}
