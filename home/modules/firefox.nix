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
        # === Hardware Acceleration ===
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "layers.acceleration.force-enabled" = true;

        # === TELEMETRY DISABLING (PRIVACY + PERFORMANCE) ===
        
        # Core telemetry
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.server" = "";
        
        # Data reporting and health reports
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.healthreport.service.enabled" = false;
        
        # Crash reporting
        "breakpad.reportURL" = "";
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
        
        # Studies, experiments, and A/B testing
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "experiments.enabled" = false;
        "experiments.supported" = false;
        "experiments.activeExperiment" = false;
        "messaging-system.rsexperimentloader.enabled" = false;
        
        # Coverage telemetry
        "toolkit.coverage.opt-out" = true;
        "toolkit.coverage.endpoint.base" = "";
        
        # Firefox Suggest (search telemetry)
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
        
        # Captive portal detection (phones home to detect.mozilla.com)
        "captivedetect.canonicalURL" = "";
        "network.captive-portal-service.enabled" = false;
        
        # Network connectivity checks
        "network.connectivity-service.enabled" = false;
        
        # DNS over HTTPS telemetry
        "network.trr.confirmation_telemetry_enabled" = false;
        
        # Personalization and recommendations
        "browser.discovery.enabled" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        
        # === PRIVACY SETTINGS ===
        
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
