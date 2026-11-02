# Home Manager for graphical hosts (imported by the workstation role):
# the niri session, terminal and default apps. Bigger topics live next to it.
{
  imports = [
    ./bitwarden.nix
    ./ivpn.nix
    ./noctalia.nix
    ./rbw.nix
    ./rclone.nix
    ./theme.nix
  ];

  # --- niri --------------------------------------------------------------------
  # niri-session starts niri.service, which binds graphical-session.target, so
  # units on the default wayland.systemd.target (Noctalia) start with it.
  xdg.configFile."niri/config.kdl".source = ../../files/niri/config.kdl;

  # --- Terminal ----------------------------------------------------------------
  programs.kitty = {
    enable = true;
    font.name = "CommitMono Nerd Font";
    themeFile = "kanagawa_dragon"; # from kitty-themes
  };

  # --- Default apps --------------------------------------------------------------
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.kde.okular.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
}
