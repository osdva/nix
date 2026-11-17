# Repo-wide overlays, composed into one overlay for nixpkgs.overlays.
# Add a file here and extend `overlays` below.
let
  overlays = [
    (import ./gearlever.nix)
    (import ./openspec.nix)
    (import ./trayscale.nix)
  ];
in
final: prev: builtins.foldl' (acc: overlay: acc // (overlay final acc)) prev overlays
