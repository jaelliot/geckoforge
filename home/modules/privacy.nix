# @file home/modules/privacy.nix
# @description Privacy and telemetry disabling configuration
# @update-policy Update when new telemetry sources discovered or privacy hardening needed
# @performance-impact Reduces network I/O, CPU usage from background telemetry collection

{ config, lib, pkgs, ... }:

with lib;

{
  options.geckoforge.privacy = {
    disableTelemetry = mkOption {
      type = types.bool;
      default = true;
      description = "Disable all telemetry and analytics across system";
    };
    
    disableAnalytics = mkOption {
      type = types.bool;
      default = true;
      description = "Disable usage analytics in development tools";
    };
  };
  
  config = mkMerge [
    (mkIf config.geckoforge.privacy.disableTelemetry {
      # Environment variables for various development tools
      home.sessionVariables = {
        # === Language Toolchains ===
        
        # Go telemetry (Go 1.23+)
        GOTELEMETRY = "off";
        GOTELEMETRYDIR = "/dev/null";
        
        # Elixir/Phoenix telemetry
        ELIXIR_CLI_TELEMETRY = "false";
        MIX_TELEMETRY_DISABLED = "1";
        
        # Node.js frameworks
        NEXT_TELEMETRY_DISABLED = "1";      # Next.js
        ASTRO_TELEMETRY_DISABLED = "1";     # Astro
        GATSBY_TELEMETRY_DISABLED = "1";    # Gatsby
        
        # Rust toolchain
        CARGO_TELEMETRY_DISABLED = "1";
        
        # .NET CLI
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        
        # Python
        PYTHONDONTWRITEBYTECODE = "1";  # No .pyc files (reduces disk I/O)
        
        # === Package Managers ===
        
        # Homebrew (if ever used)
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_AUTO_UPDATE = "1";
        
        # npm
        DISABLE_OPENCOLLECTIVE = "1";
        ADBLOCK = "1";
        
        # === Cloud CLIs ===
        
        # Azure CLI
        AZURE_CORE_COLLECT_TELEMETRY = "false";
        
        # PowerShell (if used)
        POWERSHELL_TELEMETRY_OPTOUT = "1";
        
        # AWS CLI (doesn't have telemetry, but disable metrics collection)
        AWS_DEFAULT_OUTPUT = "json";
        
        # === Build Tools ===
        
        # CMake
        CMAKE_NO_USER_PACKAGE_REGISTRY = "1";
        
        # === General ===
        
        # Disable automatic error reporting
        DO_NOT_TRACK = "1";
      };
      
      # Docker config - disable analytics
      home.file.".docker/config.json".text = builtins.toJSON {
        auths = {};
        analyticsEnabled = false;
        autoUpdate = false;
      };
      
      # KDE Plasma feedback (user surveys, crash reports)
      xdg.configFile."PlasmaUserFeedback".text = ''
        [Global]
        Enabled=false
      '';
      
      # KDE crash handler (Dr. Konqi) - keep local, don't upload
      xdg.configFile."drkonqirc".text = ''
        [DrKonqi]
        Enabled=true
        # Keep crash reporting local for debugging
        # but don't automatically upload
        AutoSubmit=false
      '';
      
      # npm config - disable telemetry
      home.file.".npmrc".text = ''
        # Disable npm telemetry
        disable-telemetry=true
        
        # Disable package funding messages
        fund=false
        
        # Disable update notifications
        update-notifier=false
      '';
      
      # Git configuration - minimal tracking
      programs.git.extraConfig = {
        # Don't phone home for credential helpers
        credential.helper = "";
        
        # Disable auto-gc (manual garbage collection preferred)
        gc.auto = 0;
      };
    })
    
    (mkIf config.geckoforge.privacy.disableAnalytics {
      # Additional analytics disabling for services
      home.sessionVariables = {
        # Terraform
        CHECKPOINT_DISABLE = "1";
        
        # Hasura
        HASURA_GRAPHQL_ENABLE_TELEMETRY = "false";
        
        # Storybook
        STORYBOOK_DISABLE_TELEMETRY = "1";
      };
    })
  ];
  
  meta = {
    maintainers = [ "Jay Elliot" ];
    description = "Privacy-focused configuration disabling telemetry across all tools";
  };
}
