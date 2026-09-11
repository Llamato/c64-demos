{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    dotfiles-llamato = {
      url = "github:llamato/dotfiles";
      flake = true;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      darwinSystem = [
        "aarch64-darwin"
      ];
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
      ];
      allSystems = linuxSystems ++ darwinSystem;
    in
    inputs.flake-utils.lib.eachSystem linuxSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        llvm-mos-sdk = inputs.nixpkgs-llamato.packages.${system}.llvm-mos-sdk;
        psid = inputs.dotfiles-llamato.packages.${system}.psid;
        vchar64 = inputs.dotfiles-llamato.packages.${system}.vchar64;
        metaOf = name: {
          description = "";
          maintainers = with lib.maintainers; [ llamato ];
        };
        acme-build =
          name:
          pkgs.stdenv.mkDerivation {
            name = "${name}-acme";
            version = "0.0.1";
            meta = metaOf name;
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
        basic-build =
          name:
          pkgs.stdenv.mkDerivation {
            name = "${name}-basic";
            version = "0.0.1";
            meta = metaOf name;
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
        binary-build =
          name:
          pkgs.stdenv.mkDerivation {
            name = "${name}-bins";
            version = "0.0.1";
            meta = metaOf name;
            src = ./${name};
            installPhase = ''
              mkdir -p $out
              cp *.bin $out
            '';
          };
        disk-build =
          paths: name:
          pkgs.stdenv.mkDerivation {
            name = "${name}-d64";
            version = "0.0.1";
            meta = metaOf name;
            src = pkgs.symlinkJoin {
              inherit name;
              inherit paths;
            };
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
          charsets = disk-build [
            (acme-build "charsets")
            (basic-build "charsets")
            (binary-build "charsets")
          ] "charsets";
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
        apps = builtins.mapAttrs (name: drv: {
          type = "app";
          program = "${pkgs.writeShellScript "run-${name}" ''exec ${pkgs.vice}/bin/x64sc $(find ${drv}/ -name "${name}.prg" -o -name "${name}.d64" | head -1) "$@"''}";
          meta = metaOf name;
        }) demos;
        devShells =
          let
            packagesByDevShell = rec {
              default = with pkgs; [
                vice
                rehex
                sidplayfp
                psid
                vchar64
                acme
              ];
              cc = default ++ [llvm-mos-sdk];
            };
          in builtins.mapAttrs (_: packages: pkgs.mkShell {
            packages = packages;
          }) packagesByDevShell;
      }
    );
}
