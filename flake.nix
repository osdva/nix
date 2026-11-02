{
  description = "osdva's multi-host NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib { inherit inputs; };
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      # One entry per machine. `roles` pick modules/nixos/roles/<role>.nix;
      # everything machine-specific lives in hosts/<name>/.
      nixosConfigurations = {
        tkpd = lib.mkHost {
          hostname = "tkpd";
          roles = [
            "workstation"
            "laptop"
            "development"
          ];
        };

        # Examples (uncomment after creating hosts/<name>/ — see docs/hosts.md):
        # desktop = lib.mkHost { hostname = "desktop"; roles = [ "workstation" "development" ]; };
        # homelab = lib.mkHost { hostname = "homelab"; roles = [ "server" ]; };
        # pi      = lib.mkHost { hostname = "pi"; system = "aarch64-linux"; roles = [ "server" ]; };
      };

      # `nix develop` (or direnv) installs the pre-commit hook: gitleaks blocks
      # commits that stage a secret.
      devShells = forAllSystems (
        system:
        let
          hooks = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks.gitleaks.enable = true;
          };
        in
        {
          default = nixpkgs.legacyPackages.${system}.mkShell {
            inherit (hooks) shellHook;
            packages = hooks.enabledPackages;
          };
        }
      );

      # `nix fmt`
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # `nix flake check` builds every host's toplevel.
      checks = forAllSystems (
        system:
        nixpkgs.lib.mapAttrs'
          (name: host: nixpkgs.lib.nameValuePair "host-${name}" host.config.system.build.toplevel)
          (
            nixpkgs.lib.filterAttrs (
              _: host: host.pkgs.stdenv.hostPlatform.system == system
            ) self.nixosConfigurations
          )
      );
    };
}
