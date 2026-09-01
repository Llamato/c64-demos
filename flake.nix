{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    dotfiles-llamato = {
      url = "github:llamato/dotfiles";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
        "aarch64-darwin"
      ];
    in
    inputs.flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        llvm-mos-sdk = pkgs.callPackage (inputs.dotfiles-llamato + "/nixos/packages/llvm-mos-sdk/package.nix") { };
        psid = pkgs.callPackage (inputs.dotfiles-llamato + "/nixos/packages/psid/package.nix") { };
        vchar64 = pkgs.callPackage (inputs.dotfiles-llamato + "/nixos/packages/vchar64/package.nix") { };
        acme-build = name: pkgs.stdenv.mkDerivation {
          name = "${name}-acme";
          version = "0.0.1";
          src = ./${name};
          buildPhase = ''
            runHook preBuild
            ${pkgs.acme}/bin/acme --cpu 6510 --format cbm -o ${name}.prg main.asm
            runHook postBuild
          '';
          installPhase = ''
            mkdir -p $out
            cp ${name}.prg $out
          '';
        };
        basic-build = name: pkgs.stdenv.mkDerivation {
          name = "${name}-basic";
          version = "0.0.1";
          src = ./${name};
          buildPhase = ''
            runHook preBuild
            find . -name "*.bas" -execdir sh -c '${pkgs.vice}/bin/petcat -w2 -o $1.prg -- $1' sh {} \;
            runHook postBuild
          '';
          installPhase = ''
            mkdir -p $out
            cp *.bas.prg $out
          '';
        };
        binary-build = name: pkgs.stdenv.mkDerivation {
          name = "${name}-bins";
          version = "0.0.1";
          src = ./${name};
          installPhase = ''
            mkdir -p $out
            cp *.bin $out
          '';
        };
        disk-build = paths: name: pkgs.symlinkJoin {
          inherit paths;
          name = "${name}-d64";
          version = "0.0.1";
          buildPhase = ''
            ${pkgs.vice}/bin/c1541 -format ${name},0 d64 ${name}.d64
            find . -name "*.prg" -a \! \( -name "*.bas.*" \) -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .prg)"' sh {} \;
            find . -name "*.bas.prg" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach "${name}.d64" -write "$1" "$(basename "$1" .bas.prg)"' sh {} \;
            find . -name "*.seq" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .seq)"' sh {} \;
            find . -name "*.bin" -execdir sh -c '${pkgs.vice}/bin/c1541 -attach ${name}.d64 -write "$1" "$(basename "$1" .bin)"' sh {} \;
          '';
          installPhase = ''
            mkdir -p $out
            cp ${name}.d64 $out
          '';
        };
        demos = {
          kneedeepin3d = pkgs.stdenv.mkDerivation {
            name = "kneedeepin3d";
            version = "0.0.1";
            src = ./kneedeepin3d/.;
            buildPhase = ''
              runHook preBuild
              ${llvm-mos-sdk}/bin/mos-c64-clang -Os main.c gllm/gllm.c -o kneedeepin3d.prg
              runHook postBuild
            '';
            installPhase = ''
              mkdir -p $out
              cp kneedeepin3d.prg $out
            '';
          };
          multisprite = acme-build "multisprite";
          spritemultiplexing = acme-build "spritemultiplexing";
          smoothpaddles = acme-build "smoothpaddles";
          random = acme-build "random";
          sidplayer = acme-build "sidplayer";
          kneedeepin2d = acme-build "kneedeepin2d";
          charsets = disk-build [(acme-build "charsets") (basic-build "charsets") (binary-build "charsets")] "charsets";
        };
      in
      {
        packages = {
          default = pkgs.symlinkJoin {
            name = "c64-demos";
            paths = builtins.attrValues demos;
          };
        }
        // demos;
        apps = builtins.mapAttrs (name: drv: 
        {
            type = "app";
            program = "${pkgs.writeShellScript "run-${name}" ''exec ${pkgs.vice}/bin/x64sc $(find ${drv}/ -name "${name}.prg" -o -name "${name}.d64" | head -1) "$@"''}";
          }) demos;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            acme
            vice
            ghc
            rehex
            sidplayfp
            llvm-mos-sdk
            psid
            vchar64
          ];
        };
      }
    );
}
