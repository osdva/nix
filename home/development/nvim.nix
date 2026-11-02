# Neovim: the config is read-only from the store, but vim.pack must be able
# to rewrite its lockfile, so that one file links back into this repo —
# plugin updates show up as a git diff in this repo.
{ config, flakeDir, ... }:
{
  xdg.configFile."nvim/init.lua".source = ../../files/nvim/init.lua;
  xdg.configFile."nvim/lua".source = ../../files/nvim/lua;
  xdg.configFile."nvim/after".source = ../../files/nvim/after;
  xdg.configFile."nvim/nvim-pack-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink "${flakeDir}/files/nvim/nvim-pack-lock.json";
}
