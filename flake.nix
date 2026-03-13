{
  description = "a bash script that takes an HTML file and uses Chromium to
  render it as a PDF. Chromium is not from nix right now because of Darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/6d41bc27aaf7b6a3ba6b169db3bd5d6159cfaa47";
    nixpkgs-master.url = "github:NixOS/nixpkgs/5b7e21f22978c4b740b3907f3251b470f466a9a2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    chromium-html-to-pdf.url = "github:friedenberg/chromium-html-to-pdf";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
      chromium-html-to-pdf,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        name = "pa6e-markdown-to-html";
        buildInputs = with pkgs; [
          uv
          bluez
          imagemagick
          pandoc
          chromium-html-to-pdf.packages.${system}.html-to-pdf
        ];
        pa6e-markdown-to-html =
          (pkgs.writeScriptBin name (builtins.readFile ./markdown-to-html.bash)).overrideAttrs
            (old: {
              buildCommand = "${old.buildCommand}\n patchShebangs $out";
            });

        pa6e = pkgs.rustPlatform.buildRustPackage {
          pname = "pa6e";
          version = "0.1.0";
          src = ./rs;
          cargoLock.lockFile = ./rs/Cargo.lock;
          nativeBuildInputs = with pkgs; [ pkg-config ];
          buildInputs = with pkgs; [ dbus ];
        };

        # to include all the templates and styles
        src = ./.;

      in
      rec {
        packages.pa6e-markdown-to-html = pkgs.symlinkJoin {
          name = name;
          paths = [
            pa6e-markdown-to-html
            src
          ]
          ++ buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
        };

        packages.pa6e = pa6e;

        defaultPackage = packages.pa6e-markdown-to-html;

        devShells.default = pkgs.mkShell {
          packages = (
            with pkgs;
            [
              bluez
              uv
              imagemagick
              pandoc
              cargo
              rustc
              pkg-config
              dbus
              chromium-html-to-pdf.packages.${system}.html-to-pdf
            ]
          );

          LD_LIBRARY_PATH = [ "${pkgs.bluez.out}/lib" ];

          inputsFrom = [ ];
        };
      }
    );
}
