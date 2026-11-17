# Home Manager for graphical hosts (imported by the workstation role):
# the niri session, terminal and default apps. Bigger topics live next to it.
{ pkgs, ... }:
{
  imports = [
    ./bitwarden.nix
    ./noctalia.nix
    ./rbw.nix
    ./rclone.nix
    ./tailscale.nix
    ./theme.nix
    ./windscribe.nix
    ./zen.nix
  ];

  # --- Loose AppImage manager ---------------------------------------------------
  # Gear Lever integrates raw AppImages into the launcher, checks for updates
  # and can sandbox them via Firejail.
  home.packages = [
    pkgs.gearlever
    # AirPods: noise control, battery, ear detection, etc. Wrapped because the
    # global QT_STYLE_OVERRIDE=adwaita-dark (nixos.qt.style) is a Qt Widgets
    # style, and Qt Quick Controls refuses it: Main.qml fails to load with
    # `module "adwaita-dark" is not installed` and the app runs without a
    # window. A Qt Quick Controls app needs that variable unset.
    (pkgs.librepods.overrideAttrs (prev: {
      nativeBuildInputs = prev.nativeBuildInputs ++ [ pkgs.makeWrapper ];
      postFixup = (prev.postFixup or "") + ''
        wrapProgram $out/bin/librepods --unset QT_STYLE_OVERRIDE
      '';
    }))
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
      "text/html" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "application/pdf" = "org.kde.okular.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };
}
