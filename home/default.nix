# Home Manager for every host (servers included): shell, git, CLI tools.
{
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./secrets.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "26.05";
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
