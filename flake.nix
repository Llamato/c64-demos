{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    cbmNix = {
      url = "github:llamato/cbmNix";
    };
    dotfiles-llamato = {
      url = "github:llamato/dotfiles";
      flake = true;
    };
  };

  outputs =
    { 
      self, 
      nixpkgs,
        ... 
    }@inputs:
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
        gpkgs = with inputs.dotfiles-llamato.packages.${system}; {
          llvm-mos-sdk = llvm-mos-sdk;
          psid = psid;
          vchar64 = vchar64;
          multipaint = multipaint;
        };
        pkgs = import nixpkgs { inherit system; } // gpkgs;
        lib = pkgs.lib;
        cbmNix = inputs.cbmNix.lib.mk { inherit pkgs; };

        demos = {
          kneedeepin3d = cbmNix.buildClangPrg;
          multisprite = cbmNix.buildAcmePrg;
          spritemultiplexing = cbmNix.buildAcmePrg;
          smoothpaddles = cbmNix.buildAcmePrg;
          random = cbmNix.buildAcmePrg;
          sidplayer = cbmNix.buildAcmePrg;
          kneedeepin2d = cbmNix.buildAcmePrg;
          charsets = [
            cbmNix.buildAcmePrg
            cbmNix.buildBasicPrgs
            cbmNix.buildBinaryPrgs
          ];
          printing = [
            cbmNix.buildAcmePrg
            cbmNix.buildPetsciiTextFiles
          ];
          conway = [
            cbmNix.buildAcmePrg
            cbmNix.buildBasicPrgs
          ];
        };
 
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
          includedFiles = [ "*.bin" ];
          removeFileExtension = true;
          targetSystem = "c64";
          starfile = "${name}.prg";
          clangFlags = [
            "-Os"
            "main.c"
            "gllm/gllm.c"
            "-o ${name}.prg"
          ];
          acmeFlags = [
            "--cpu 6510"
            "--format cbm"
            "-o ${name}.prg"
          ]
          ++ lib.optional debug "--vicelabels ${name}.vicelabels"
          ++ [ 
            "main.asm" 
          ];
        };
        makeDemo =
          builders: demoAttrs:
          if builtins.isList builders then
            let
              d64 = cbmNix.buildD64 {
              name = demoAttrs.name;
              paths = (map (builder: builder demoAttrs)) builders;
              debug = demoAttrs.debug;
              starfile = demoAttrs.starfile;
            };
            sourceFiles = pkgs.runCommand "collect-debug-artifacts" demoAttrs ''
              mkdir -p $out
              cp -R $src/* $out
            '';
            in if demoAttrs.debug then pkgs.symlinkJoin {
              name = "${demoAttrs.name}-debug";
              paths = [
                d64
                sourceFiles
              ];
            } else d64
          else
            builders demoAttrs;
        demoPackages = builtins.foldl' (
          demoBuilds: demoAttributes:
          demoBuilds
          // {
            ${demoAttributes.name} = makeDemo demoAttributes.value (attrsOf demoAttributes.name false);
          }
        ) { } (lib.attrsToList demos);
      in
      {
        packages = {
          default = pkgs.symlinkJoin {
            name = "c64-demos";
            paths = builtins.attrValues demoPackages;
          };
        }
        // demoPackages;

        apps = builtins.mapAttrs (name: drv: {
          type = "app";
          program = "${pkgs.writeShellScript "run-${name}" ''exec ${pkgs.vice}/bin/x64sc $(${findDemoArtifactCommandFor name drv}) "$@"''}";
          meta = demoMeta;
        }) demoPackages;

        checks =
          let
            checksFilename = "checks.nix";
          in
          builtins.mapAttrs (
            drvname: builders:
            let
              checksFilePath = ./${drvname}/${checksFilename};
              drvattrs = attrsOf drvname true;
              drv = makeDemo builders drvattrs;
            in
            pkgs.linkFarm "${drvname}-checks" (
              [
                {
                  name = "build-artifacts-exists";
                  path = (
                    pkgs.runCommand "${drvname}-runner-test"
                      {

                      }
                      ''
                        ARTIFACTS=$(${findDemoArtifactCommandFor drvname drv})
                        [ -f $ARTIFACTS ] || exit 1
                        mkdir -p $out
                        echo $ARTIFACTS > $out/artifacts.txt
                        touch $out/pass
                      ''
                  );
                }
              ]
              ++ lib.optionals (builtins.pathExists checksFilePath) (
                lib.mapAttrsToList
                  (tname: tdrv: {
                    name = tname;
                    path = tdrv;
                  })
                  (
                    import checksFilePath {
                      inherit pkgs cbmNix drvname drv;
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
                #multipaint
              ];
              cc = default ++ [ pkgs.llvm-mos-sdk ];
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
