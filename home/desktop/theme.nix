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
  };
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    document-font-name = "Adwaita Sans 11";
    monospace-font-name = "CommitMono Nerd Font 11";
  };
}
