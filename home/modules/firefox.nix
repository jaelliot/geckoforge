# @file home/modules/firefox.nix
# @description Firefox browser with privacy-focused extensions and hardened settings
# @update-policy Update when Firefox extensions or privacy settings need adjustment

{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        lastpass
        proton-pass-firefox
        libredirect
        auto-tab-discard
        downthemall
        link-gopher
        colorzilla
        image-search-options
        old-reddit-redirect
        unhook-youtube
        grammarly
      ];

      search = {
        default = "Google";
        force = false;

        engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };

          "GitHub" = {
            urls = [{
              template = "https://github.com/search";
              params = [
                { name = "q"; value = "{searchTerms}"; }
              ];
            }];
            definedAliases = [ "@gh" ];
          };

          "Amazon.com".metaData.hidden = true;
          "Bing".metaData.hidden = true;
        };
      };

      settings = {
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "layers.acceleration.force-enabled" = true;

        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "privacy.partition.network_state.ocsp_cache" = true;

        "browser.newtabpage.enabled" = true;
        "browser.newtabpage.activity-stream.feeds.topsites" = true;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = true;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        "dom.security.https_only_mode" = true;
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "network.predictor.enabled" = false;

        "browser.aboutwelcome.enabled" = false;
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "extensions.pocket.enabled" = false;
        "extensions.screenshots.disabled" = true;

        "network.cookie.cookieBehavior" = 1;

        "browser.uidensity" = 1;
        "browser.tabs.inTitlebar" = 1;

        "browser.download.useDownloadDir" = true;
        "browser.download.folderList" = 1;
      };
    };
  };
}
