# Home Manager for graphical hosts (imported by the workstation role):
# the mango session, terminal and default apps. Bigger topics live next to it.
{
  imports = [
    ./bitwarden.nix
    ./noctalia.nix
    ./rbw.nix
    ./rclone.nix
    ./theme.nix
  ];

  # --- mango -------------------------------------------------------------------
  xdg.configFile."mango/config.toml".source = ../../files/mango/config.toml;

  # Units tied to config.wayland.systemd.target (Noctalia) start only in mango.
  wayland.systemd.target = "mango-session.target";

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
