# Coding agents: Claude Code and pi. Imported by home/development.nix.
#
# API keys are never in this repo: they're read from Bitwarden at runtime with
# rbw (home/secrets.nix). Convention: one Bitwarden item "API-Keys" with one
# custom field per key (OPENCODE_API_KEY, EXA_API_KEY, ...):
#   rbw get --field OPENCODE_API_KEY API-Keys
{ pkgs, ... }:
let
  secret = field: "rbw get --field ${field} API-Keys";
in
{
  # --- Claude Code -------------------------------------------------------------
  programs.claude-code = {
    enable = true;
    # Claude Code also writes settings (/model, /config): merge declared keys
    # into a writable ~/.claude/settings.json instead of a read-only link.
    mutableSettings = true;
    settings = {
      theme = "dark-daltonized";
      model = "opus";
    };
  };

  # --- pi ----------------------------------------------------------------------
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
      apiKey = "!${secret "OPENCODE_API_KEY"}";
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
    ".pi/agent/extensions".source = ../files/pi/extensions;
    ".pi/agent/agents".source = ../files/pi/agents;
    ".pi/agent/prompts".source = ../files/pi/prompts;
  };

  # --- opencode ----------------------------------------------------------------
  # opencode only reads {env:...} from its config, so the wrapper below hands it
  # the Context7 key for that one process.
  programs.opencode = {
    enable = true;
    settings = {
      agent = {
        plan = {
          model = "openai/gpt-5.5";
          reasoningEffort = "high";
        };
        build.model = "opencode-go/kimi-k2.6";
      };
      enabled_providers = [
        "openai"
        "opencode-go"
      ];
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
        notion = {
          type = "remote";
          url = "https://mcp.notion.com/mcp";
        };
      };
    };
  };
  programs.fish.functions.opencode = ''
    CONTEXT7_API_KEY=(${secret "CONTEXT7_API_KEY"} 2>/dev/null) command opencode $argv
  '';
}
