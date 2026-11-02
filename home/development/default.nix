# Developer machines (imported by the development role): toolchains, editor,
# coding agents, containers.
{ pkgs, ... }:
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
  ];

  # Podman's Docker-compatible socket.
  home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
}
