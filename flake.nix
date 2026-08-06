{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-26.05";
    dotfiles-llamato.url = "github:llamato/dotfiles";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      dotfiles-llamato,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "riscv64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      lib = nixpkgs.lib;
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        llvm-mos = pkgs.callPackage (dotfiles-llamato + "/nixos/packages/llvm-mos-sdk/package.nix") { };
        fetchD64 =
          {
            url,
            sha256 ? "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
          }:
          let
            name =
              let
                path = builtins.head (lib.splitString "?" url);
                parts = lib.splitString "/" path;
                filtered = lib.filter (s: s != "") parts;
              in
              if filtered == [ ] then "downloaded-file" else lib.last filtered;
          in
          pkgs.stdenv.mkDerivation {
            name = "${name}-extracted";
            src = builtins.fetchurl { inherit url sha256 name; };
            buildPhase = ''
              ${pkgs.vice}/bin/c1541 -attach "$src" -extract
            '';
          };
        acme-build =
          name:
          pkgs.stdenv.mkDerivation {
            name = name;
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
        demos = {
          kneedeepin3d = pkgs.stdenv.mkDerivation {
            name = "kneedeepin3d";
            version = "0.0.1";
            src = ./kneedeepin3d/.;
            buildPhase = ''
              runHook preBuild
              ${llvm-mos}/bin/mos-c64-clang -Os main.c gllm/gllm.c -o kneedeepin3d.prg
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
        };
      in
      {
        packages = {
          default = pkgs.symlinkJoin {
            name = "c64-demos";
            paths = builtins.attrValues demos;
          };
        } // demos;
        apps = {
          
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            acme
            vice
            llvm-mos
          ];
        };
      }
    );
}
