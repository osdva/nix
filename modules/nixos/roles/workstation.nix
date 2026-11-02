# Graphical machine: niri + Noctalia, ly login, audio, fonts, desktop apps,
# Bitwarden (SSH agent + fingerprint unlock).
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
{
  home-manager.users.${user}.imports = [ ../../../home/desktop ];

  # --- Session ----------------------------------------------------------------
  programs.niri.enable = true;

  # Noctalia is started by home-manager inside the niri session.
  programs.noctalia.enable = true;
  security.pam.services.noctalia = { };

  # Login: ly (TUI). niri is the only session. Auth goes through
  # the `login` PAM stack, which also unlocks gnome-keyring.
  services.displayManager = {
    defaultSession = "niri";
    ly = {
      enable = true;
      # Keys: `ly`'s config.ini (ly 1.5).
      settings = {
        allow_empty_password = false;
        clock = "%a %d %b  %H:%M";
        bigclock = "en";
        numlock = true;
        # Only niri in the list (a plain TTY is on Ctrl+Alt+F2).
        shell = false;
        xinitrc = null;
      };
    };
  };

  # Qt apps (okular, ...) follow the dark Adwaita look.
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # --- SSH agent: Bitwarden only ------------------------------------------------
  # No competing agents; ssh/git talk to ~/.bitwarden-ssh-agent.sock (see home/desktop/bitwarden.nix).
  programs.ssh.startAgent = false;
  services.gnome.gcr-ssh-agent.enable = false;
  programs.gnupg.agent.enableSSHSupport = false;

  # The kernel disables hibernation while any process holds memfd_secret memory,
  # and Bitwarden Desktop uses it for its key ("Using memfd_secret for secure key
  # storage"), so with Bitwarden running /sys/power/disk shows [disabled].
  # Turning memfd_secret off makes Bitwarden fall back to the kernel keyring
  # (keyctl), which still keeps the key out of process memory. Only needed on
  # hosts that hibernate (laptop role).
  boot.kernelParams = lib.mkIf (config.boot.resumeDevice != "") [ "secretmem.enable=0" ];

  # --- Desktop plumbing ---------------------------------------------------------
  services.gnome.gnome-keyring.enable = true;
  security.rtkit.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true; # D-Bus service Home Manager's dconf.settings writes through
  services.udisks2.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.accounts-daemon.enable = true;
  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Fingerprint: polkit + sudo; never at login (the keyring needs the password).
  services.fprintd.enable = lib.mkDefault true;
  security.pam.services = {
    login.fprintAuth = false;
    polkit-1.fprintAuth = true;
    sudo.fprintAuth = true;
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      adwaita-fonts
      dejavu_fonts
      liberation_ttf
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      carlito
      corefonts
      cascadia-code
      nerd-fonts.commit-mono
      nerd-fonts.geist-mono
      nerd-fonts.blex-mono
    ];
  };

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    bitwarden-cli
    nautilus
    loupe
    vlc
    kdePackages.okular
    obsidian
    vesktop
    mission-center
    cider-2 # Apple Music client (sign in with your Cider account + Apple ID)
    wl-clipboard
    cliphist
    brightnessctl
    pavucontrol
    adwaita-icon-theme
    xwayland-satellite
  ];
}
