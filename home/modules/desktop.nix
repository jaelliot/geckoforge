{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    chromium
  ];

  programs.chromium = {
    enable = true;

    extensions = [
      # Manifest V2-compatible extensions focused on privacy and developer tooling
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # uBlock Origin
      { id = "gcbommkclmclpchllfjekcdonpmejbdp"; } # HTTPS Everywhere
      { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger
      { id = "fmkadmapgofadopljbjfkapdkoienihi"; } # React Developer Tools
      { id = "hfhhnacclhffhdffklopdkcgdhifgngh"; } # Altair GraphQL Client
      { id = "mdnleldcmiljblolnjhpnblkcekpdkpa"; } # Requestly
      { id = "hlepfoohegkhhmjieoechaddaejaokhf"; } # Refined GitHub
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock for YouTube
    ];

    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder,CanvasOopRasterization"
      "--enable-gpu-rasterization"
      "--force-dark-mode"
      "--disable-features=UseChromeOSDirectVideoDecoder,MediaRouter"
      "--disable-background-networking"
      "--disable-default-apps"
      "--disable-search-engine-choice-screen"
      "--disable-sync"
      "--metrics-recording-only"
      "--no-default-browser-check"
      "--password-store=basic"
      "--ozone-platform-hint=auto"
    ];
  };
}
