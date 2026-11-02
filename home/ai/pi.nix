# pi coding agent: settings, providers, MCP servers, and the extensions,
# agents and prompts kept in files/pi/.
{ pkgs, rbwSecret, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    # pi installs its `npm:` packages itself and needs these on PATH.
    extraPackages = with pkgs; [
      nodejs
      bun
      rbw
    ];
    # pi writes back things like lastChangelogVersion.
    mutableSettings = true;
    settings = {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-6.1-sol";
      defaultThinkingLevel = "medium";
      hideThinkingBlock = true;
      theme = "dark";
      packages = [
        "npm:pi-claude-bridge@0.9.2"
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
      models = [
        {
          id = "kimi-k2.5";
          name = "Kimi K2.5 (OpenCode Go)";
        }
        {
          id = "glm-5";
          name = "GLM-5 (OpenCode Go)";
        }
        {
          id = "minimax-m2.5";
          name = "MiniMax M2.5 (OpenCode Go)";
        }
      ];
    };
  };

  home.file = {
    ".pi/agent/mcp.json".text = builtins.toJSON {
      mcpServers = {
        figma = {
          url = "https://mcp.figma.com/mcp";
          oauth.clientName = "Claude Code";
          description = "Figma design files, components, variables, and Dev Mode context";
        };
        firecrawl = {
          url = "https://mcp.firecrawl.dev/v2/mcp-oauth";
          description = "Search, scrape, crawl, map, and research the web with Firecrawl";
        };
      };
    };
    ".pi/agent/extensions".source = ../../files/pi/extensions;
    ".pi/agent/agents".source = ../../files/pi/agents;
    ".pi/agent/prompts".source = ../../files/pi/prompts;
  };
}
