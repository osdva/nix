# tmux: C-a prefix, Kanagawa Dragon, nvim-aware pane navigation.
{ lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    shell = lib.getExe pkgs.fish;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      # aserowy/tmux.nvim isn't in nixpkgs; pinned here.
      (mkTmuxPlugin {
        pluginName = "tmux.nvim";
        rtpFilePath = "tmux.nvim.tmux";
        version = "0-unstable-5971292";
        src = pkgs.fetchFromGitHub {
          owner = "aserowy";
          repo = "tmux.nvim";
          rev = "5971292e1322c1ae1c305bd6df58e6d1bf7527bb";
          hash = "sha256-jXnVB1cd0QjcUHA61c8DFSll1sIaYFLRDAHONa9L9EE=";
        };
      })
      {
        plugin = ukiyo; # formerly tmux-kanagawa
        extraConfig = ''
          set -g @ukiyo-theme "kanagawa/dragon"
          set -g @ukiyo-ignore-window-colors true
        '';
      }
    ];
    extraConfig = ''
      set -g status-position top
      set -as terminal-features ",*:RGB"
      bind r source-file ~/.config/tmux/tmux.conf
      bind g display-popup -E -h 90% -w 90% -d '#{pane_current_path}' "lazygit || true"
      bind t display-popup -E -h 35% -w 35% -d '#{pane_current_path}'
    '';
  };
}
