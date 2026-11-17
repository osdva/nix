# nixpkgs ships trayscale 0.19.0, which subscribes to tailscaled's IPN bus
# with the NotifyInitialNetMap bit. tailscaled 1.104 removed that bit and
# answers "400 Bad Request", so the GUI never receives state and retries every
# 5s with an empty window. Upstream dropped the bit in 0.20.0; track 0.21.0
# until nixpkgs catches up (it needs Go >= 1.27.2, which nixpkgs has).
#
# 0.21 also moved to puregotk, which loads GTK's shared libraries at runtime by
# name and panics if it can't find them ("Path for library: cairo not found").
# Point it at a merged lib dir, the way nixpkgs' other puregotk apps do.
_final: prev: {
  trayscale = prev.trayscale.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "0.21.0";
      src = prev.fetchFromGitHub {
        owner = "DeedleFake";
        repo = "trayscale";
        tag = "v${finalAttrs.version}";
        hash = "sha256-8Wv+jLkGVpPfvEMVBpliOAJNG6/XVX93q3l9qIChVpg=";
      };
      vendorHash = "sha256-bxiloB4cJHY45nMYczEToCExj3ZlvDKqA7yYAbgGmi4=";

      # dist.sh's `install` mode copies ./trayscale from the source dir, but
      # buildGoModule has already put the binary in $out/bin: install the data
      # files only and compile the schema here.
      postInstall = ''
        sh ./dist.sh install-data $out
        glib-compile-schemas $out/share/glib-2.0/schemas
      '';

      # Trayscale imports puregotk's gtk, gdk, adw, gio, gobject and glib
      # packages, so those plus their own deps have to be findable in one dir.
      passthru = (prevAttrs.passthru or { }) // {
        libraryPath = prev.symlinkJoin {
          name = "trayscale-puregotk-lib";
          paths = with prev; [
            cairo
            gdk-pixbuf
            glib.out
            graphene
            gtk4
            libadwaita
            pango.out
          ];
        };
      };

      preFixup = (prevAttrs.preFixup or "") + ''
        gappsWrapperArgs+=(--set-default PUREGOTK_LIB_FOLDER ${finalAttrs.passthru.libraryPath}/lib)
      '';
    }
  );
}
