# Fix Gear Lever's broken wrapper in nixpkgs.
#
# upstream pkgs/by-name/ge/gearlever/default.nix passes
# `"${gappsWrapperArgs[@]}"` (bash array expansion) through makeWrapperArgs,
# which makeCWrapper + structuredAttrs can't expand, so the build fails with
# `#error makeCWrapper: Unknown argument`.
#
# Instead: let wrapGAppsHook do the wrapping (`dontWrapGApps = false`), add
# the PATH prefix the package needs onto gappsWrapperArgs, and empty
# makeWrapperArgs (the raw one doesn't work with makeCWrapper). The hook's
# wrapper exports the env used when exec'ing the python interpreter, so a
# single wrap is enough. Delete this overlay once the package is fixed
# upstream.
final: prev: {
  gearlever = prev.gearlever.overrideAttrs (old: {
    dontWrapGApps = false;
    makeWrapperArgs = [ ];

    preFixup = (old.preFixup or "") + ''
      gappsWrapperArgs+=(
        --prefix PATH : ${
          final.lib.makeBinPath (
            with final;
            [
              file
              _7zz # 7zz
              which
              appimage-run
              desktop-file-utils # update-desktop-database
              gtk4.dev # gtk4-launch
              bintools # readelf
              libnotify # notify-send
              dwarfs # dwarfsextract, dwarfsck
              squashfs-tools # unsquashfs
            ]
          )
        }
      )
    '';
  });
}
