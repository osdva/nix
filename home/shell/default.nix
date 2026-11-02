# Shell environment for every host: fish, prompt, CLI tools.
{ pkgs, ... }:
{
  imports = [
    ./broot.nix
    ./fish.nix
    ./lazygit.nix
    ./tmux.nix
  ];

  home.packages = with pkgs; [
    bat
    fd
    jq
    bottom
    fastfetch
    glow
    gum
    unzip
    zip
    _7zz
    tree
    trash-cli
    inotify-tools
    just
    difftastic
    delta
    gitu
    gh
    tmuxifier
    impala
    bluetui
  ];

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character.success_symbol = "[➜](bold green)";
      package.disabled = true;
      git_metrics.disabled = false;
    };
  };

  programs.zoxide.enable = true;
  programs.eza.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  xdg.configFile."fastfetch/config.jsonc".source = ../../files/fastfetch/config.jsonc;
}
