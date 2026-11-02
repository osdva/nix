# Home Manager for every host (servers included): shell, git, CLI tools.
{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./secrets.nix
  ];

  # username, homeDirectory and stateVersion come from the NixOS side
  # (modules/nixos/core).
  home = {
    sessionVariables = {
      EDITOR = "nvim";
      RIPGREP_CONFIG_PATH = "$HOME/.ripgreprc";
    };
    packages = [ pkgs.neovim ];
  };

  home.file.".ripgreprc".source = ../files/ripgreprc;

  xdg.enable = true;
  programs.home-manager.enable = true;
}
