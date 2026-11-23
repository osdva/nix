# pi coding agent: settings, providers, MCP servers, and the extensions,
# agents and prompts kept in files/pi/.
{
  pkgs,
  agentSkillsTree,
  llmAgents,
  rbwSecret,
  rtkInit,
  ...
}:
{
  programs.pi-coding-agent = {
    enable = true;
    package = llmAgents.pi;
    # pi installs its `npm:` packages itself and needs these on PATH.
    extraPackages = with pkgs; [
      nodejs
      bun
      rbw
    ];
    # pi writes back things like lastChangelogVersion.
    mutableSettings = true;
    settings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "max";
      hideThinkingBlock = true;
      theme = "dark";
      packages = [
        "npm:pi-commandcode-provider"
        "npm:pi-subagents"
        "npm:@antfu/design"
        "npm:pi-elixir"
      ];
    };
    models.providers.opencode-go = {
      baseUrl = "https://opencode.ai/zen/go/v1";
      api = "openai-completions";
      # "!cmd" = pi runs the command and uses its output as the key.
      apiKey = "!${rbwSecret "OPENCODE_API_KEY"}";
      authHeader = true;
    };
  };

  home.file = {
    # pi-commandcode-provider takes its key from COMMAND_CODE_API_KEY or an
    # auth file, not from models.providers. This is the first path it reads;
    # pi resolves a "!command" key lazily, so nothing is written in the clear.
    ".commandcode/auth.json".text = builtins.toJSON {
      command-code = {
        type = "api";
        key = "!${rbwSecret "COMMAND_CODE_API_KEY"}";
      };
    };
    ".pi/agent/mcp.json".text = builtins.toJSON {
      mcpServers = {
        # Linear API key from Bitwarden (field LINEAR_API_KEY). pi runs the
        # !command at connection time, so no secret lands in mcp.json.
        linear = {
          url = "https://mcp.linear.app/mcp";
          headers.Authorization = "!echo Bearer $(${rbwSecret "LINEAR_API_KEY"})";
          description = "Linear issues, projects, and documents";
        };
        paper = {
          type = "stdio";
          command = "/home/osdva/.paper/bin/paper";
          args = [ "mcp" ];
        };
        # Same remote servers as opencode and Claude Code (home/ai/opencode.nix,
        # home/ai/claude-code.nix). The token reaches pi through the wrapper
        # below, so it never enters the Nix store.
        baratorama-admin = {
          url = "https://baratorama-vps.ribbon-gila.ts.net/admin/mcp";
          headers.Authorization = "Bearer \${ADMIN_MCP_TOKEN}";
          description = "Baratorama admin MCP: inbox, catalog search, failure groups, review clusters, operations";
        };
        # Storybook's MCP endpoint, served by the design app on port 6006.
        storybook = {
          url = "http://127.0.0.1:6006/mcp";
          description = "Storybook component and page docs for the design system";
        };
        # Figma design context. Authorise over OAuth once: `pi mcp login figma`.
        figma = {
          url = "https://mcp.figma.com/mcp";
          description = "Figma files, components, and design context";
        };
      };
    };
    ".pi/agent/extensions".source = pkgs.runCommandLocal "pi-extensions" { } ''
      mkdir -p "$out"
      ln -s ${../../files/pi/extensions}/* "$out/"
      ln -s ${rtkInit}/.pi/agent/extensions/rtk.ts "$out/rtk.ts"
    '';
    ".pi/agent/agents".source = ../../files/pi/agents;
    ".pi/agent/prompts".source = ../../files/pi/prompts;
    ".pi/agent/skills".source = agentSkillsTree;
  };

  # pi expands ${ADMIN_MCP_TOKEN} inside mcp.json headers. Hand it the token for
  # that one process, like opencode does with CONTEXT7_API_KEY.
  programs.fish.functions.pi = ''
    ADMIN_MCP_TOKEN=(${rbwSecret "ADMIN_MCP_TOKEN"} 2>/dev/null) command pi $argv
  '';
}
