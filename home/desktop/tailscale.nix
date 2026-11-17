# Trayscale: GTK4/libadwaita front end for the tailscaled daemon that the core
# module already runs (peer list, exit nodes, taildrop sends — the things the
# CLI makes tedious).
#
# Trayscale drives tailscaled through its LocalAPI socket, which is root-only
# unless the user is the daemon's "operator". core/default.nix sets that at
# boot via services.tailscale.extraSetFlags; without it the window opens with a
# permission-denied banner and every action fails.
#
# No autostart: Trayscale draws no tray icon (the name is aspirational), so a
# service would either pop a window at every login or hide invisibly. Open it
# from the launcher when you want it.
{ pkgs, ... }:
{
  home.packages = [ pkgs.trayscale ];
}
