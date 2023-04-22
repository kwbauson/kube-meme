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
  node_bin = pkgs.runCommand "node_bin" { } ''
    mkdir -p $out/bin
    cp -s ${node_modules}/bin/{tsc,ts-node,vite} $out/bin
  '';
in
{
  name = "meme";
  scripts = mapAttrs (_: exec: { inherit exec; }) {
    start = "minikube start";
    stop = "minikube stop";
  };

  enterShell = ''
    mkdir -p node_modules
    rm -f node_modules/*
    ln -s ${node_modules}/node_modules/* node_modules
  '';

  processes = mapAttrs (_: exec: { inherit exec; }) {
    frontend = "vite --port 4000 frontend";
    backend = "ts-node backend/server.ts";
    caddy = "caddy run";
  };

  env = {
    npm_config_package_lock_only = true;
  };

  packages = with pkgs; [
    minikube
    kubectl
    nodejs
    caddy
    xh
    node_bin
  ];
}
