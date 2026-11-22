# Developer machines (imported by the development role): toolchains, editor,
# coding agents, containers.
{
  lib,
  pkgs,
  rbwSecret,
  ...
}:
let
  beadsWithLinear = pkgs.symlinkJoin {
    name = "beads-${pkgs.beads.version}";
    paths = [ pkgs.beads ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/bd \
        --prefix PATH : ${lib.makeBinPath [ pkgs.rbw ]} \
        --run 'export LINEAR_API_KEY="$(${rbwSecret "LINEAR_API_KEY"} 2>/dev/null)"'
    '';
  };
in
{
  imports = [
    ../ai
    ./languages.nix
    ./nvim.nix
  ];

  home.packages = with pkgs; [
    # Nix
    nixd
    nixfmt
    nix-output-monitor
    nvd

    # Containers / data
    podman-compose
    lazydocker
    lazysql
    rclone

    # Spec workflow (pinned ahead of nixpkgs, see overlays/openspec.nix)
    openspec

    # Issue tracker for AI agent workflows; the binary is `bd`. The wrapper
    # supplies LINEAR_API_KEY from Bitwarden for `bd linear sync` and the
    # Linear integration, so the key stays out of the git-tracked config.
    beadsWithLinear
  ];

  # Podman's Docker-compatible socket.
  home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
}
