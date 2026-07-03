{
  description = "development environment for c64 assembly applications using acme assembler";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    llamato-dotfiles.url = "github:llamato/dotfiles";
  };

  outputs =
    { self, nixpkgs, ... } @inputs:
    let
      systems = [
        "x86_64-linux"
        #Coming soon... llvm-mos package not ready yet
        #"aarch64-linux"
        #"aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          llvm-mos = pkgs.callPackage (inputs.llamato-dotfiles + "/nixos/packages/llvm-mos/package.nix") { };
        in
        {

          multisprite = pkgs.stdenv.mkDerivation {
            name = "multisprite";
            version = "0.0.1";
            src = ./multisprite/.;
            buildPhase = ''
              runHook preBuild
              ${pkgs.acme}/bin/acme --cpu 6510 --format cbm -o multisprite.prg multisprite.asm
              runHook postBuild
            '';
            installPhase = ''
              cp multisprite.prg $out
            '';
          };

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
              cp kneedeepin3d.prg $out
            '';
          };
        }
      );
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          llvm-mos = pkgs.callPackage (inputs.llamato-dotfiles + "/nixos/packages/llvm-mos/package.nix") { };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              acme
              vice
              llvm-mos
            ];
          };
        }
      );
    };
}
