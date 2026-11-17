# Skills are shared with pi and opencode (files/skills). Claude gets one
# symlink per skill instead of the whole directory, so the entries Claude and
# orca manage themselves (~/.claude/skills/orca-*, ~/.claude/skills/synced)
# stay untouched.
{ lib, rbwSecret, ... }:
let
  skillsDir = ../../files/skills;
  skillNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );
in
{
  programs.claude-code = {
    enable = true;
    # Claude Code also writes settings (/model, /config): merge declared keys
    # into a writable ~/.claude/settings.json instead of a read-only link.
    mutableSettings = true;
    settings = {
      theme = "dark-daltonized";
      model = "opus";
    };
    # Same remote servers as opencode and pi (home/ai/opencode.nix,
    # home/ai/pi.nix). The token is expanded from the environment, which the
    # fish wrapper below fills from Bitwarden.
    mcpServers = {
      baratorama-admin = {
        type = "http";
        url = "https://baratorama-vps.ribbon-gila.ts.net/admin/mcp";
        headers.Authorization = "Bearer \${ADMIN_MCP_TOKEN}";
      };
      storybook = {
        type = "http";
        url = "http://127.0.0.1:6006/mcp";
      };
    };
  };

  programs.fish.functions.claude = ''
    ADMIN_MCP_TOKEN=(${rbwSecret "ADMIN_MCP_TOKEN"} 2>/dev/null) command claude $argv
  '';

  home.file = lib.listToAttrs (
    map (name: {
      name = ".claude/skills/${name}";
      value.source = skillsDir + "/${name}";
    }) skillNames
  );
}
