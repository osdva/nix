# Global languages. Versions follow the pinned nixpkgs; bump with
# `nh os switch --update`. A project that needs another version gets a
# devShell + direnv.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
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
  ];

  home.sessionVariables = {
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
}
