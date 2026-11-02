# opencode only reads {env:...} from its config, so the fish wrapper below
# hands it the Context7 key for that one process.
{ rbwSecret, ... }:
{
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

  programs.fish = {
    functions.opencode = ''
      CONTEXT7_API_KEY=(${rbwSecret "CONTEXT7_API_KEY"} 2>/dev/null) command opencode $argv
    '';
    shellAliases.oc = "OPENCODE_EXPERIMENTAL=true opencode";
  };
}
