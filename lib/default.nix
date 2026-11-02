{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # Build a NixOS system from a hostname and a list of roles.
  #
  #   hostname  directory under hosts/ (hardware + host quirks + stateVersion)
  #   roles     names of files in modules/nixos/roles/ (workstation, laptop,
  #             development, server, ...)
  #   user      primary user; passed to every module as `user`
  mkHost =
    {
      hostname,
      system ? "x86_64-linux",
      roles ? [ ],
      user ? "osdva",
    }:
    lib.nixosSystem {
      specialArgs = {
        inherit inputs user hostname;
      };
      modules = [
        { nixpkgs.hostPlatform = system; }
        inputs.home-manager.nixosModules.home-manager
        ../modules/nixos/core
        ../hosts/${hostname}
      ]
      ++ map (role: ../modules/nixos/roles/${role}.nix) roles;
    };
}
