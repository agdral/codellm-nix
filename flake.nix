{
  description = "CodeLLM packaged as a Nix binary from GitHub releases";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Update these two lines for each new release:
        #codellmVersion = "1.99.32404";
        codellmVersion = "1.99.32500";
        codellmSha256 = "sha256-LN5nAiP8LSH2I70bg/mX/B81UT9lglA15kC5+haP4/M=";
        #codellmSha256 = "sha256-Wdy2plOI/batpRAiN8Uc+iNMgVRt7nl0EXeyXzDuzxc=";

        # FIX: Define the required runtime libraries in one place.
        # These are needed for both build-time patching and the runtime FHS environment.
        runtimeLibs = with pkgs; [
          musl
          glib
          gtk3
          pango
          cairo
          xorg.libX11
          xorg.libxcb
          xorg.libXext
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXfixes
          xorg.libXrandr
          libgbm
          mesa
          libGL
          libGLU
          expat
          libxkbcommon
          systemd
          alsa-lib
          atk
          nss
          nspr
          dbus
          cups
          at-spi2-atk
          at-spi2-core
          gdk-pixbuf
          libdrm
          xorg.libXScrnSaver
          xorg.libXtst
          xorg.libXi
          xorg.libXcursor
          fontconfig
          freetype
          xorg.libxkbfile
          zlib
        ];

        # This is the FHS environment containing all of Electron's runtime dependencies.
        # The actual application will be run inside this sandbox.
        fhs = pkgs.buildFHSEnv {
          name = "codellm-fhs-env";
          # Use the shared list of libraries
          targetPkgs = pkgs: runtimeLibs;
          # The environment provides a shell that we will use to execute our app.
          runScript = "bash";
        };

      in
      {
        # This is the main package definition.
        packages.codellm = pkgs.stdenv.mkDerivation {
          pname = "codellm";
          version = codellmVersion;

          # Fetch the release tarball
          src = pkgs.fetchurl {
            url = "https://github.com/abacusai/codellm-releases/releases/download/${codellmVersion}/CodeLLM-linux-x64-${codellmVersion}.tar.gz";
            sha256 = codellmSha256;
          };

          # Tell stdenv that the source root is the current directory
          # because the archive unpacks to multiple files/dirs.
          sourceRoot = ".";

          # We need makeWrapper to create the launcher script and autoPatchelfHook
          # to fix the binary for the Nix environment.
          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.autoPatchelfHook
          ];

          # FIX: Provide the runtime libraries to autoPatchelfHook
          # so it can find them during the build.
          buildInputs = runtimeLibs;

          # The install phase is where we build the final package structure.
          installPhase = ''
                        runHook preInstall

                        # Create standard directories for the application, binaries, and desktop files.
                        mkdir -p $out/lib/codellm $out/bin $out/share/applications $out/share/pixmaps

                        # Copy the already-unpacked contents from the build directory
                        # into our desired location in the Nix store.
                        cp -r ./* $out/lib/codellm/

                        # Find the application icon, assuming it's named 'icon.png' somewhere in the package.
                        # Electron apps often bundle it this way.
                        APP_ICON_PATH=$(find $out/lib/codellm -name icon.png | head -n 1)
                        if [ -f "$APP_ICON_PATH" ]; then
                          cp "$APP_ICON_PATH" $out/share/pixmaps/codellm.png
                        fi

                        # Create a wrapper script. This is the magic.
                        # It creates an executable file at $out/bin/codellm that runs the *real*
                        # binary ($out/lib/codellm/codellm) inside the FHS sandbox.
            	    #makeWrapper ${fhs}/bin/codellm-fhs-env $out/bin/codellm \
            	    # --add-flags "$out/lib/codellm/codellm"
            	    makeWrapper ${fhs}/bin/codellm-fhs-env $out/bin/codellm \
            	      --add-flags "$out/lib/codellm/bin/codellm"

                        # Create the .desktop file needed for application launchers like Fuzzel.
                        cat > $out/share/applications/codellm.desktop <<EOF
                        [Desktop Entry]
                        Name=CodeLLM
                        Comment=CodeLLM AI Coding Assistant
                        Exec=$out/bin/codellm
                        Icon=codellm
                        Type=Application
                        Categories=Development;
                        StartupWMClass=CodeLLM
                        EOF

                        runHook postInstall
          '';
        };

        # Set our new package as the default for this flake.
        packages.default = self.packages.${system}.codellm;
      }
    );
}
