{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kitty
  ];

  programs.chromium = {
    enable = true;

    extensions = [
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      { id = "nngceckbapebfimnlniiiahkandclblb"; }
    ];

    commandLineArgs = [
      "--enable-features=VaapiVideoDecoder"
      "--disable-features=UseChromeOSDirectVideoDecoder"
      "--disable-background-networking"
      "--disable-sync"
      "--disable-google-traffic"
      "--disable-crashpad"
    ];
  };
}
