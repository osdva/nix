# opencode only reads {env:...} from its config, so the fish wrapper below
# hands it the Context7 key, the admin MCP token and the Linear API key for
# that one process.
{ opencodeCli, rbwSecret, ... }:
{
  programs.opencode = {
    enable = true;
    # OpenCode 2, exposed as `opencode` (see home/ai/default.nix).
    package = opencodeCli;
    # Shared skills reach opencode through ~/.agents/skills (home/ai/default.nix).
    settings = {
      default_agent = "coordinator";
      # Plan review and code review in the browser. The installer adds the
      # plannotator binary and the /plannotator-* commands.
      plugins = [ "@plannotator/opencode@latest" ];
      agent = {
        plan = {
          model = "openai/gpt-5.5";
          reasoningEffort = "high";
        };
        build.model = "opencode-go/kimi-k2.6";
        explore.model = "opencode-go/deepseek-v4.1-flash#max";
        general.model = "opencode-go/deepseek-v4.1-flash#max";
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
        # Same MCP servers as pi (home/ai/pi.nix). Linear authenticates with an API
        # key from Bitwarden (field LINEAR_API_KEY). The plugin below injects the
        # header; {env:...} is the fallback for shell launches.
        # oauth = false so a missing key fails instead of opening a sign-in prompt.
        linear = {
          type = "remote";
          url = "https://mcp.linear.app/mcp";
          headers.Authorization = "Bearer {env:LINEAR_API_KEY}";
          oauth = false;
        };
        # Baratorama admin API and the design app's Storybook.
        # The bearer token comes from Bitwarden: the plugin below injects the
        # header, and {env:...} stays as a fallback for shell-launched sessions.
        # oauth = false because the endpoint only accepts that token, so a
        # missing token fails clearly instead of opening a sign-in prompt.
        baratorama-admin = {
          type = "remote";
          url = "https://baratorama-vps.ribbon-gila.ts.net/admin/mcp";
          headers.Authorization = "Bearer {env:ADMIN_MCP_TOKEN}";
          oauth = false;
        };
        storybook = {
          type = "remote";
          url = "http://127.0.0.1:6006/mcp";
        };
        # Figma design context. Authorise over OAuth once:
        # `opencode mcp auth figma`.
        figma = {
          type = "remote";
          url = "https://mcp.figma.com/mcp";
        };
      };
    };
  };

  programs.fish = {
    functions.opencode = ''
      CONTEXT7_API_KEY=(${rbwSecret "CONTEXT7_API_KEY"} 2>/dev/null) ADMIN_MCP_TOKEN=(${rbwSecret "ADMIN_MCP_TOKEN"} 2>/dev/null) LINEAR_API_KEY=(${rbwSecret "LINEAR_API_KEY"} 2>/dev/null) command opencode $argv
    '';
    shellAliases.oc = "OPENCODE_EXPERIMENTAL=true opencode";
  };

  # Plannotator installs its binary here and the /plannotator-* commands
  # shell out to it, so the path must be on PATH.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # The coordinator, developer and verifier agents are available to every
  # project; their model pins live in the files themselves.
  xdg.configFile = {
    "opencode/agents/coordinator.md".source = ../../files/opencode/agents/coordinator.md;
    "opencode/agents/developer.md".source = ../../files/opencode/agents/developer.md;
    "opencode/agents/verifier.md".source = ../../files/opencode/agents/verifier.md;
    # Reads the admin MCP token from Bitwarden at startup, since OpenCode cannot
    # fetch a secret from configuration. See the file for the entry it reads.
    "opencode/plugins/baratorama-admin-token/index.js".source =
      ../../files/opencode/plugins/baratorama-admin-token/index.js;
    # Reads LINEAR_API_KEY from Bitwarden and injects the Linear MCP header.
    "opencode/plugins/linear-token/index.js".source =
      ../../files/opencode/plugins/linear-token/index.js;
  };
}
