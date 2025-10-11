{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
    chromium
    
    # Essential fonts for development and desktop
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "SourceCodePro" ]; })
    fira-code
    jetbrains-mono
    source-code-pro
    ubuntu-font-family
    liberation_ttf
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
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

  # Font configuration for development and desktop use
  fonts.fontconfig.enable = true;
  
  # Terminal configuration with development-focused font
  programs.kitty = {
    enable = true;
    font = {
      name = "FiraCode Nerd Font Mono";
      size = 12;
    };
    settings = {
      # Font rendering
      font_family = "FiraCode Nerd Font Mono";
      bold_font = "FiraCode Nerd Font Mono Bold";
      italic_font = "FiraCode Nerd Font Mono Italic";
      bold_italic_font = "FiraCode Nerd Font Mono Bold Italic";
      
      # Font features for better coding
      font_features = "FiraCode-Regular +cv01 +cv02 +cv05 +cv09 +cv14 +cv16 +cv18 +cv25 +cv26 +cv28 +cv29 +cv30 +cv31";
      disable_ligatures = "never";
      
      # Terminal appearance
      background_opacity = "0.95";
      window_padding_width = "8";
      scrollback_lines = "10000";
      
      # Development-friendly colors (Gruvbox Dark)
      foreground = "#ebdbb2";
      background = "#282828";
      selection_foreground = "#655b53";
      selection_background = "#ebdbb2";
      
      # Gruvbox color palette
      color0 = "#282828";
      color1 = "#cc241d";
      color2 = "#98971a";
      color3 = "#d79921";
      color4 = "#458588";
      color5 = "#b16286";
      color6 = "#689d6a";
      color7 = "#a89984";
      color8 = "#928374";
      color9 = "#fb4934";
      color10 = "#b8bb26";
      color11 = "#fabd2f";
      color12 = "#83a598";
      color13 = "#d3869b";
      color14 = "#8ec07c";
      color15 = "#ebdbb2";
    };
  };
}
