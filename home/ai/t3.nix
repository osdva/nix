# T3 Code: the `t3` server/CLI and the desktop control surface.
#
# Upstream's t3code wrapper puts a default provider set on PATH: Codex, Claude,
# Cursor, Grok and OpenCode. Override it to the agents used here, otherwise T3
# pulls Codex and the others into the closure.
{ llmAgents, opencodeCli, ... }:
let
  t3code = llmAgents.t3code.override {
    providerPackages = [
      # The same v2 CLI the `opencode` command uses (home/ai/opencode.nix).
      opencodeCli
      llmAgents.claude-code
      llmAgents.pi
      llmAgents.antigravity-cli
      llmAgents.rtk
    ];
  };
in
{
  home.packages = [
    t3code
    # The desktop output is built by the same derivation; point it at the
    # overridden package so it does not pull the default provider set back in.
    (llmAgents.t3code-desktop.override { inherit t3code; })
  ];
}
