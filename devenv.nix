{ pkgs, ... }@args:
let
  inherit (builtins) mapAttrs filterSource elem;
  inherit (pkgs) nodejs;
  npmlock2nix = (import args.npmlock2nix { inherit pkgs; }).v2;
  src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
  node_modules = npmlock2nix.node_modules {
    inherit nodejs;
    src = filterSource (p: _: elem (baseNameOf p) [ "package.json" "package-lock.json" ]) src;
  };
  node_modules_bins = pkgs.runCommand "node_modules_bins" { } ''
    mkdir -p $out/bin
    cp -s ${node_modules}/bin/{tsc,ts-node} $out/bin
  '';
in
{
  name = "meme";
  scripts = mapAttrs (_: exec: { inherit exec; }) {
    start = ''
      minikube start
    '';
    stop = ''
      minikube stop
    '';
  };

  env = {
    npm_config_package_lock_only = true;
  };

  packages = with pkgs; [
    minikube
    kubectl
    nodejs
    xh
    node_modules_bins
  ];

  enterShell = ''
    ln -sf ${node_modules}/node_modules .
  '';

  processes.backend.exec = ''
    ts-node ./backend/server.ts
  '';
}
