# Skills are shared with pi and opencode (files/skills). Claude gets one
# symlink per skill instead of the whole directory, so the entries Claude and
# orca manage themselves (~/.claude/skills/orca-*, ~/.claude/skills/synced)
# stay untouched.
{
  agentSkills,
  llmAgents,
  rbwSecret,
  rtkInit,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = llmAgents.claude-code;
    mutableSettings = true;
    settings = {
      theme = "dark-daltonized";
      model = "opus";
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];
    };
    # The admin token is expanded from the environment, which the fish wrapper
    # below fills from Bitwarden; Linear uses headersHelper.
    mcpServers = {
      # Linear API key from Bitwarden (field LINEAR_API_KEY). The helper runs at
      # connection time and prints the Authorization header as JSON.
      linear = {
        type = "http";
        url = "https://mcp.linear.app/mcp";
        headersHelper = "printf '{\"Authorization\": \"Bearer %s\"}' \"$(${rbwSecret "LINEAR_API_KEY"} 2>/dev/null)\"";
      };
      baratorama-admin = {
        type = "http";
        url = "https://baratorama-vps.ribbon-gila.ts.net/admin/mcp";
        headers.Authorization = "Bearer \${ADMIN_MCP_TOKEN}";
      };
      storybook = {
        type = "http";
        url = "http://127.0.0.1:6006/mcp";
      };
      # Figma design context. Authorise over OAuth once via `/mcp`.
      figma = {
        type = "http";
        url = "https://mcp.figma.com/mcp";
      };
    };
  };

  programs.fish.functions.claude = ''
    ADMIN_MCP_TOKEN=(${rbwSecret "ADMIN_MCP_TOKEN"} 2>/dev/null) command claude $argv
  '';

  home.file =
    builtins.listToAttrs (
      map (s: {
        name = ".claude/skills/${s.name}";
        value.source = s.source;
      }) agentSkills
    )
    // {
      ".claude/RTK.md".source = "${rtkInit}/.claude/RTK.md";
      ".claude/CLAUDE.md".source = "${rtkInit}/.claude/CLAUDE.md";
    };
}
