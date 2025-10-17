{ config, lib, pkgs, ... }:

let
  cfg = config.geckoforge.security;

  firefoxPolicies = pkgs.writeText "firefox-policies.json" ''
{
  "policies": {
    "DisableAppUpdate": true,
    "DisableFeedbackCommands": true,
    "DisableFirefoxAccounts": true,
    "DisablePasswordReveal": true,
    "DisablePocket": true,
    "DisableProfileImport": true,
    "DisableTelemetry": true,
    "DNSOverHTTPS": {
      "Enabled": true,
      "ProviderURL": "https://dns.quad9.net/dns-query"
    },
    "Homepage": {
      "URL": "about:blank",
      "Locked": false
    },
    "ExtensionSettings": {
      "uBlock0@raymondhill.net": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
      },
      "jid1-MnnxcxisBPnSXQ@jetpack": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/https-everywhere/latest.xpi"
      },
      "search@clearurls": {
        "installation_mode": "force_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi"
      },
      "*": {
        "installation_mode": "blocked"
      }
    },
    "OfferToSaveLogins": false,
    "PasswordManagerEnabled": false,
    "SearchBar": "separate",
    "SanitizeOnShutdown": true
  }
}
'';

  sandboxedApps = [
    {
      id = "org.mozilla.firefox";
      allowedPaths = [ "xdg-download" ];
    }
    {
      id = "org.chromium.Chromium";
      allowedPaths = [ "xdg-download" ];
    }
    {
      id = "org.libreoffice.LibreOffice";
      allowedPaths = [ "xdg-documents" "xdg-download" ];
    }
  ];

  overrideCommands = lib.concatMapStrings (app:
    ''
        flatpak override --user --reset ${app.id} || true
        flatpak override --user --nofilesystem=home ${app.id}
''
    + lib.concatMapStrings (path:
      ''
        flatpak override --user --filesystem=${path} ${app.id}
''
    ) app.allowedPaths
  ) sandboxedApps;

in {
  options.geckoforge.security.enable = lib.mkEnableOption "geckoforge security hardening (sandboxed apps, tools, policies)";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      bubblewrap
      dnsutils
      flatpak
      rkhunter
    ];

    home.activation.sandboxedFlatpaks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if command -v flatpak >/dev/null 2>&1; then
        flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo || true
        install_or_update() {
          local app="$1"
          flatpak install -y --user flathub "$app" || true
        }
        install_or_update org.mozilla.firefox
        install_or_update org.chromium.Chromium
        install_or_update org.libreoffice.LibreOffice
${overrideCommands}
      else
        echo "[security] flatpak not available; skipping sandboxed apps" >&2
      fi
    '';

    home.file.".var/app/org.mozilla.firefox/config/firefox/policies/policies.json" = {
      source = firefoxPolicies;
    };

    # Provide convenient wrappers that prefer Flatpak binaries
    home.file.".local/bin/firefox" = {
      executable = true;
      text = ''#!/usr/bin/env bash
exec flatpak run org.mozilla.firefox "$@"
'';
    };

    home.file.".local/bin/chromium" = {
      executable = true;
      text = ''#!/usr/bin/env bash
exec flatpak run org.chromium.Chromium "$@"
'';
    };

    home.file.".local/bin/libreoffice" = {
      executable = true;
      text = ''#!/usr/bin/env bash
exec flatpak run org.libreoffice.LibreOffice "$@"
'';
    };
  };
}
