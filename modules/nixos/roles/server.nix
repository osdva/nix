# Headless homelab machine. Home Manager still provides the shell/git setup
# from home/default.nix; nothing graphical is installed.
{ lib, ... }:
{
  # No desktop: keep the console keymap only.
  services.xserver.enable = false;
  networking.networkmanager.enable = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault true;

  # Servers are managed remotely, e.g.
  #   nixos-rebuild switch --flake ~/dev/nix#homelab --target-host homelab --sudo
  security.sudo.wheelNeedsPassword = false;

  services.openssh.openFirewall = true; # core keeps it closed by default
  documentation.nixos.enable = false;

  # Keep running after the admin logs out (containers, tmux sessions).
  services.logind.settings.Login.KillUserProcesses = false;
}
