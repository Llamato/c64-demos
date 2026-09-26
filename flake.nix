{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    cbmNix.url = "github:llamato/cbmNix";
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
    inputs.flake-utils.lib.eachSystem allSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        cbmNix = inputs.cbmNix.lib.mk { inherit pkgs; };

        llvm-mos-sdk = inputs.dotfiles-llamato.packages.${system}.llvm-mos-sdk;
        psid = inputs.dotfiles-llamato.packages.${system}.psid;
        vchar64 = inputs.dotfiles-llamato.packages.${system}.vchar64;
        multipaint = inputs.dotfiles-llamato.packages.${system}.multipaint;

        demoMeta = {
          description = "";
          maintainers = with lib.maintainers; [ llamato ];
        };
        attrsOf = name: {
          inherit name;
          version = "0.0.1";
          src = ./${name};
          meta = demoMeta;
        };
        demos = {
          kneedeepin3d = pkgs.stdenv.mkDerivation {
            name = "kneedeepin3d";
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
          multisprite = cbmNix.buildAcmePrg (attrsOf "multisprite");
          spritemultiplexing = cbmNix.buildAcmePrg (attrsOf "spritemultiplexing");
          smoothpaddles = cbmNix.buildAcmePrg (attrsOf "smoothpaddles");
          random = cbmNix.buildAcmePrg (attrsOf "random");
          sidplayer = cbmNix.buildAcmePrg (attrsOf "sidplayer");
          kneedeepin2d = cbmNix.buildAcmePrg (attrsOf "kneedeepin2d");
          charsets = cbmNix.buildD64 [
            (cbmNix.buildAcmePrg (attrsOf "charsets"))
            (cbmNix.buildBasicPrg (attrsOf "charsets"))
            (cbmNix.buildBinaryAsset (attrsOf "charsets"))
          ] "charsets";
          printing = cbmNix.buildD64 [
            (cbmNix.buildAcmePrg (attrsOf "printing"))
            #(cbmNix.buildBasicPrg (attrsOf "printing"))
            (cbmNix.buildTextAsset (attrsOf "printing"))
          ] "printing";
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
          meta = demoMeta;
        }) demos;
        devShells =
          let
            packagesByDevShell = rec {
              default = with pkgs; [
                vice
                rehex
                sidplayfp
                acme
                psid
                vchar64
                multipaint
              ];
              cc = default ++ [ llvm-mos-sdk ];

            };
          in
          builtins.mapAttrs (
            _: packages:
            pkgs.mkShell {
              packages = packages;
            }
          ) packagesByDevShell;
      }
    );
}
