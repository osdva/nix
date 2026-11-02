# Look & feel: cursor, GTK, dark mode, fonts.
{ pkgs, ... }:
{
  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
  };
  # Owns gtk-{3,4}.0/settings.ini and the matching dconf keys (what the settings
  # portal hands to GTK4 apps like Nautilus).
  # No theme/extraCss, so gtk.css stays Noctalia's.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
    };
    # Electron (Bitwarden, Obsidian, ...) takes its first dark/light answer from
    # GTK 3 and only gets the portal's color-scheme a moment later; some apps
    # keep the first one. GTK 4/libadwaita warn about this key, so GTK 3 only.
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    document-font-name = "Adwaita Sans 11";
    monospace-font-name = "CommitMono Nerd Font 11";
  };
}
