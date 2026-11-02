# fish: aliases, helper functions, fzf.fish keybindings.
{ pkgs, flakeDir, ... }:
{
  programs.fish = {
    enable = true;
    shellAliases = {
      bt = "bluetui";
      cat = "bat";
      cd = "z";
      g = "gitu";
      ls = "eza --color --icons --git -a";
      lsql = "lazysql";
      lzd = "lazydocker";
      sr = "exec fish";
      vim = "nvim";
      wf = "impala";
    };
    functions = {
      # Edit the NixOS/Home Manager config.
      dot = ''
        set -l original_dir $PWD
        cd ${flakeDir} && nvim $argv
        cd $original_dir
      '';
      # Rebuild this machine from flakeDir via nh.
      udot = "nh os switch $argv";
    };
    plugins = [
      {
        name = "fzf-fish";
        inherit (pkgs.fishPlugins.fzf-fish) src;
      }
    ];
    interactiveShellInit = ''
      set -g fish_greeting
      set --global fish_key_bindings fish_default_key_bindings

      fzf_configure_bindings --directory=\cf --git_status=\cs --processes=\cp
      set fzf_diff_highlighter delta --paging=never --width=20
      set fzf_fd_opts --hidden --max-depth 5

      tmuxifier init - fish | source
    '';
  };

  programs.fzf = {
    enable = true;
    # fzf.fish owns the keybindings.
    enableFishIntegration = false;
    defaultOptions = [
      "--cycle"
      "--layout=reverse"
      "--border"
      "--height=90%"
      "--preview-window=wrap"
      "--marker=*"
    ];
  };
}
