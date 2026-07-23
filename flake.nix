{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    dotfiles-llamato.url = "github:llamato/dotfiles";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in flake-utils.lib.eachSystem supportedSystems (system: let
        pkgs = import nixpkgs { inherit system; };
        acme-build = name: pkgs.stdenv.mkDerivation {
          name = name;
          version = "0.0.1";
          src = ./${name};
          buildPhase = ''
            runHook preBuild
            ${pkgs.acme}/bin/acme --cpu 6510 --format cbm -o result.prg main.asm
            runHook postBuild
          '';
          installPhase = ''
            cp result.prg $out
          '';
        };
        packages = {
          kneedeepin3d = pkgs.stdenv.mkDerivation {
            name = "kneedeepin3d";
            version = "0.0.1";
            src = ./kneedeepin3d/.;
            buildPhase = ''
              runHook preBuild
              ${pkgs.llvm-mos-sdk}/bin/mos-c64-clang -Os main.c gllm/gllm.c -o kneedeepin3d.prg
              runHook postBuild
            '';
            installPhase = ''
              cp kneedeepin3d.prg $out
            '';
          };
          multisprite = acme-build "multisprite";
          spritemultiplexing = acme-build "spritemultiplexing";
          smoothpaddles = acme-build "smoothpaddles";
        };
      in
      {
        inherit packages;
        apps = {
          multisprite = {
            type = "app";
            program = "${pkgs.vice}/bin/x64sc ${packages.multisprite}";
          };
          spritemultiplexing = {
            type = "app";
            program = "${pkgs.vice}/bin/x64sc ${packages.spritemultiplexing}";
          };
          smoothpaddles = {
            type = "app";
            program = "${pkgs.vice}/bin/x64sc ${packages.smoothpaddles}";
          };
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ acme vice dotfiles-llamato.packages.llvm-mos-sdk ];
        };
      }
    );
}