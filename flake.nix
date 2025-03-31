{
  inputs = {
    flakelight.url = "github:nix-community/flakelight";
    grain.url = "github:spotandjake/grain-nix";
  };
  outputs = { flakelight, grain, ... }:
    flakelight ./. ({ lib, ... }: {
      systems = lib.systems.flakeExposed;
      devShell = {
        packages = pkgs: [
          grain.packages.${pkgs.system}.default # Grain compiler
          pkgs.go-task # task command - script runner
        ];
      };
    });
}