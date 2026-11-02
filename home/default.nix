# Home Manager for every host (servers included): shell, git, CLI tools.
{ pkgs, ... }:
{
  imports = [
    ./shell
    ./git.nix
    ./secrets.nix
  ];

  # username, homeDirectory and stateVersion come from the NixOS side
  # (modules/nixos/core).
  home = {
    sessionVariables = {
      EDITOR = "nvim";
    };
    packages = [ pkgs.neovim ];
  };

  # Writes ~/.config/ripgrep/ripgreprc and sets RIPGREP_CONFIG_PATH.
  programs.ripgrep = {
    enable = true;
    arguments = [
      "--hidden"
      "--glob=!.git/*"
      "--smart-case"
    ];
  };

  xdg.enable = true;
  programs.home-manager.enable = true;
}
