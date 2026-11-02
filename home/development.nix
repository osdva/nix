# Toolchains and dev tools. Global versions come from the
# pinned nixpkgs; per-project versions come from a devShell + direnv.
{
  config,
  pkgs,
  flakeDir,
  ...
}:
{
  imports = [ ./ai.nix ];

  home.packages = with pkgs; [
    # --- Global languages -----------------------------------------------------
    # Versions follow the pinned nixpkgs; bump with `nh os switch --update`.
    # A project that needs another version gets a devShell.

    # JavaScript / TypeScript
    nodejs
    pnpm
    bun
    deno
    aube

    # Python
    python3
    uv

    # Go
    go

    # Rust (declarative toolchain instead of rustup)
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Elixir / Erlang (nvim uses the `expert` LSP)
    beamPackages.elixir
    beamPackages.erlang
    beamPackages.rebar3

    # Lua (nvim config, stylua via Mason)
    luajit
    luarocks

    # C toolchain for native extensions (node-gyp, NIFs, cgo, Mason builds)
    gcc
    gnumake
    pkg-config
    tree-sitter

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

  home.sessionVariables = {
    # Podman's Docker-compatible socket (was hosts/tkpd/fish.local.fish).
    DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    # Global installs (`npm i -g`, `go install`, `cargo install`) go to $HOME,
    # never into the read-only store.
    NPM_CONFIG_PREFIX = "$HOME/.local/share/npm";
    GOPATH = "$HOME/.local/share/go";
    CARGO_HOME = "$HOME/.local/share/cargo";
    # Keep iex history across sessions.
    ERL_AFLAGS = "-kernel shell_history enabled";
  };
  home.sessionPath = [
    "$HOME/.local/share/npm/bin"
    "$HOME/.local/share/go/bin"
    "$HOME/.local/share/cargo/bin"
  ];

  # Neovim: the config is read-only from the store, but vim.pack must be able
  # to rewrite its lockfile, so that one file links back into this repo —
  # plugin updates show up as a git diff in this repo.
  xdg.configFile."nvim/init.lua".source = ../files/nvim/init.lua;
  xdg.configFile."nvim/lua".source = ../files/nvim/lua;
  xdg.configFile."nvim/after".source = ../files/nvim/after;
  xdg.configFile."nvim/nvim-pack-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink "${flakeDir}/files/nvim/nvim-pack-lock.json";
}
