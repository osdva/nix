# broot file browser, with a `br` launcher that can cd the shell on exit.
{
  programs.broot = {
    enable = true;
    enableFishIntegration = false; # `br` is defined below
  };
  xdg.configFile."broot/conf.hjson".source = ../../files/broot/conf.hjson;
  xdg.configFile."broot/verbs.hjson".source = ../../files/broot/verbs.hjson;

  programs.fish.functions.br = {
    wraps = "broot";
    body = ''
      set -l cmd_file (mktemp)
      if broot --outcmd $cmd_file $argv
          source $cmd_file
          rm -f $cmd_file
      else
          set -l code $status
          rm -f $cmd_file
          return $code
      end
    '';
  };
}
