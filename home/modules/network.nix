# @file home/modules/network.nix
# @description Network security configuration (DNS-over-TLS, VPN)
# @update-policy Update when DNS providers or security requirements change

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.network;
  
  dnsProviders = {
    quad9 = {
      servers = [ "9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" ];
      description = "Quad9 (privacy-focused, malware blocking)";
    };
    cloudflare = {
      servers = [ "1.1.1.1#cloudflare-dns.com" "1.0.0.1#cloudflare-dns.com" ];
      description = "Cloudflare (fast, privacy-focused)";
    };
    google = {
      servers = [ "8.8.8.8#dns.google" "8.8.4.4#dns.google" ];
      description = "Google Public DNS (reliable, not privacy-focused)";
    };
  };
  
  selectedProvider = dnsProviders.${cfg.dns.provider};
  
in

{
  options.programs.network = {
    enable = mkEnableOption "network security configuration";
    
    dns = {
      provider = mkOption {
        type = types.enum [ "quad9" "cloudflare" "google" ];
        default = "quad9";
        description = "DNS provider for DNS-over-TLS";
      };
      
      enableDNSSEC = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DNSSEC validation";
      };
      
      fallbackServers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Fallback DNS servers (plain DNS)";
      };
    };
    
    vpn = {
      installProtonVPN = mkOption {
        type = types.bool;
        default = false;
        description = "Install ProtonVPN CLI (if available in repos)";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Generate systemd-resolved configuration
    xdg.configFile."systemd/resolved.conf.d/10-geckoforge-secure-dns.conf".text = ''
      [Resolve]
      DNS=${concatStringsSep " " selectedProvider.servers}
      ${optionalString (cfg.dns.fallbackServers != []) "FallbackDNS=${concatStringsSep " " cfg.dns.fallbackServers}"}
      DNSOverTLS=yes
      ${optionalString cfg.dns.enableDNSSEC "DNSSEC=yes"}
      Domains=~.
    '';
    
    # Installation helper script
    home.file.".local/bin/install-secure-dns" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Install secure DNS configuration system-wide
        
        echo "Installing secure DNS configuration..."
        echo "Provider: ${cfg.dns.provider} (${selectedProvider.description})"
        echo ""
        
        sudo mkdir -p /etc/systemd/resolved.conf.d
        sudo cp ~/.config/systemd/resolved.conf.d/10-geckoforge-secure-dns.conf /etc/systemd/resolved.conf.d/
        
        # Fix resolv.conf symlink if needed
        if [[ ! -L /etc/resolv.conf ]]; then
            echo "Fixing /etc/resolv.conf symlink..."
            sudo rm -f /etc/resolv.conf
            sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        fi
        
        sudo systemctl enable --now systemd-resolved
        sudo systemctl restart systemd-resolved
        
        echo ""
        echo "✓ Secure DNS configured"
        echo ""
        echo "Verify DNS resolution:"
        echo "  resolvectl status"
        echo "  resolvectl query cloudflare.com"
        echo ""
        echo "Test DNS-over-TLS:"
        echo "  resolvectl query --legend=no cloudflare.com"
      '';
    };
    
    # DNS verification script
    home.file.".local/bin/check-dns" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Check DNS configuration and test queries
        
        echo "=== DNS Configuration Status ==="
        echo ""
        
        if command -v resolvectl >/dev/null; then
            echo "Current DNS Settings:"
            resolvectl status | grep -A 5 "DNS Servers" || echo "  N/A"
            echo ""
            
            echo "DNS-over-TLS Status:"
            resolvectl status | grep "DNS over TLS" || echo "  N/A"
            echo ""
            
            echo "DNSSEC Status:"
            resolvectl status | grep "DNSSEC" || echo "  N/A"
            echo ""
            
            echo "Test Query (cloudflare.com):"
            resolvectl query cloudflare.com --legend=no || echo "  Query failed"
        else
            echo "resolvectl not available"
            echo "Install systemd-resolved: sudo zypper install systemd"
        fi
      '';
    };
    
    # ProtonVPN CLI (optional)
    home.packages = mkIf cfg.vpn.installProtonVPN (
      optional (pkgs ? protonvpn-cli) pkgs.protonvpn-cli
    );
    
    # Activation message
    home.activation.networkInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "[network] DNS configuration generated: ${cfg.dns.provider}"
      echo "[network] To enable: install-secure-dns"
      echo "[network] Check status: check-dns"
    '';
    
    # Shell aliases
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      dns-status = "check-dns";
      dns-test = "resolvectl query cloudflare.com";
    };
    
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      dns-status = "check-dns";
      dns-test = "resolvectl query cloudflare.com";
    };
  };
}
