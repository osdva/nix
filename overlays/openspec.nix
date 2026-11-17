# Pin OpenSpec newer than nixpkgs.
#
# nixpkgs ships openspec 1.14.3 on both unstable and master, while upstream is
# at 1.16.0. The package builds straight from the upstream GitHub tag with
# pnpm, so only the version, source hash and pnpm dependency hash move. Delete
# this overlay once nixpkgs carries 1.16.0 or newer.
_: prev: {
  openspec = prev.openspec.overrideAttrs rec {
    version = "1.16.0";

    src = prev.fetchFromGitHub {
      owner = "Fission-AI";
      repo = "OpenSpec";
      tag = "v${version}";
      hash = "sha256-T/mlLUIyJRDjXsbLDpf6kYYWH/q7pH0lPtlHkRlF8PI=";
    };

    pnpmDeps = prev.fetchPnpmDeps {
      pname = "openspec";
      inherit version src;
      pnpm = prev.pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-e6EtkUoGhZKa5v/bu2wSDl8dDiBO1KeU2x//X8hjatM=";
    };
  };
}
