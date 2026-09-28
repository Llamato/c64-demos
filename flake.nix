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

        findDemoArtifactCommandFor =
          name: drv: ''find ${drv}/ -name "${name}.prg" -o -name "${name}.d64" | head -1'';
        demoMeta = {
          description = "";
          maintainers = with lib.maintainers; [ llamato ];
        };
        attrsOf = name: debug: {
          inherit name debug;
          version = "0.0.1";
          src = ./${name};
          meta = demoMeta;
          acmeFlags = [
            "--cpu 6510"
            "--format cbm"
            "-o ${name}.prg"
          ]
          ++ lib.optional debug [
            "--vicelabels ${name}.vicelabels"
          ];
        };
        makeDemo =
          builders: name:
          let
            demoAttrs = attrsOf name false;
          in
          if builtins.isList builders then
            {
              ${name} = cbmNix.buildD64 {
                inherit name;
                paths = (map (builder: builder demoAttrs)) builders;
              };
            }
          else
            let
              builder = builders;
            in
            {
              ${name} = builder demoAttrs;
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
        }
        // makeDemo cbmNix.buildAcmePrg "multisprite"
        // makeDemo cbmNix.buildAcmePrg "spritemultiplexing"
        // makeDemo cbmNix.buildAcmePrg "smoothpaddles"
        // makeDemo cbmNix.buildAcmePrg "random"
        // makeDemo cbmNix.buildAcmePrg "sidplayer"
        // makeDemo cbmNix.buildAcmePrg "kneedeepin2d"
        // makeDemo [ cbmNix.buildAcmePrg cbmNix.buildBasicPrg cbmNix.buildBinaryAsset ] "charsets"
        // makeDemo [ cbmNix.buildAcmePrg cbmNix.buildTextAsset ] "printing";
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
          program = "${pkgs.writeShellScript "run-${name}" ''exec ${pkgs.vice}/bin/x64sc $(${findDemoArtifactCommandFor name drv}) "$@"''}";
          meta = demoMeta;
        }) demos;

        checks =
          let
            checksFile = ./checks.nix;
          in
          builtins.mapAttrs (
            name: drv:
            pkgs.linkFarm "${name}-checks" (
              [
                {
                  name = "build-artifacts-exists";
                  path = (
                    pkgs.runCommand "${name}-runner-test"
                      {

                      }
                      ''
                        ARTIFACTS=$(${findDemoArtifactCommandFor name drv})
                        [ -f $ARTIFACTS ] || exit 1
                        mkdir -p $out
                        echo $ARTIFACTS > $out/artifacts.txt
                      ''
                  );
                }
              ]
              ++ lib.optionals (builtins.pathExists checksFile) (
                lib.mapAttrsToList
                  (tname: tdrv: {
                    name = tname;
                    path = tdrv;
                  })
                  (
                    import checksFile {
                      inherit pkgs;
                      
                    }
                  )
              )
            )
          ) demos;

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
