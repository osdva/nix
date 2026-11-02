{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    fd
    ripgrep
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
    lazygit
    gitu
    gh
    tmuxifier
    impala
    bluetui
  ];

  programs.fish = {
    enable = true;
    shellAliases = {
      bt = "bluetui";
      cat = "bat";
      cd = "z";
      g = "gitu";
      hd = "herdr";
      ls = "eza --color --icons --git -a";
      lsql = "lazysql";
      lzd = "lazydocker";
      lzg = "lazygit";
      oc = "OPENCODE_EXPERIMENTAL=true opencode";
      sr = "exec fish";
      vim = "nvim";
      wf = "impala";
    };
    functions = {
      # Edit the NixOS/Home Manager config (replaces the old stow-based `dot`).
      dot = ''
        set -l original_dir $PWD
        cd ~/dev/nix && nvim $argv
        cd $original_dir
      '';
      # Rebuild this machine from ~/dev/nix via nh (replaces the stow-based `udot`).
      udot = "nh os switch $argv";
      br = {
        wraps = "broot";
        body = ''
          set -l cmd_file (mktemp)
          if broot --outcmd $cmd_file $argv
              source $cmd_file
              rm -f $cmd_file
          else
              set -l code $status
              rm -f $cmd_file
              return $code
          end
        '';
      };
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

      # Unmanaged per-machine secrets (API keys); never put these in the repo.
      if test -f ~/.config/fish/secrets.fish
          source ~/.config/fish/secrets.fish
      end
    '';
  };

  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = ../files/starship.toml;

  programs.zoxide.enable = true;
  programs.eza.enable = true;

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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  programs.broot = {
    enable = true;
    enableFishIntegration = false; # `br` is defined above
  };
  xdg.configFile."broot/conf.hjson".source = ../files/broot/conf.hjson;
  xdg.configFile."broot/verbs.hjson".source = ../files/broot/verbs.hjson;

  xdg.configFile."lazygit/config.yml".source = ../files/lazygit/config.yml;
  xdg.configFile."fastfetch/config.jsonc".source = ../files/fastfetch/config.jsonc;

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    mouse = true;
    shell = "${pkgs.fish}/bin/fish";
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
