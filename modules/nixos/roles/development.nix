# Developer machine: containers, foreign binaries, toolchains (home/development).
{ user, ... }:
{
  home-manager.users.${user}.imports = [ ../../../home/development ];

  # Lets prebuilt binaries (Mason LSPs, npm native modules, etc.) run on NixOS.
  programs.nix-ld.enable = true;

  # Rootless Podman with a Docker-compatible CLI and socket.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  users.users.${user}.extraGroups = [ "podman" ];
}
