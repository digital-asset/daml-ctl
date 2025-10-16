# Add new nixpkgs source with (find matching revision here https://lazamar.co.uk/nix-versions/):
# nix-shell -p niv --run "niv add NixOS/nixpkgs -n nixpkgs-ghc8107 -b master -r d1c3fea7ecbed758168787fe4e4a3157e52bc808"
# Update nixpkgs with:
# nix-shell -p niv --run "niv update"

let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {};
  pkgsGhc = import sources.nixpkgs-ghc8107 {};
  build_daml = import ./nix/daml.nix;
  damlYaml = builtins.fromJSON (builtins.readFile (pkgs.runCommand "daml.yaml.json" { yamlFile = ./daml.yaml; } ''
                ${pkgs.yj}/bin/yj < "$yamlFile" > $out
              ''));              
  os =
    if pkgs.stdenv.isDarwin then "macos" else
    if pkgs.stdenv.isLinux then "linux" else
    throw "Unsupported OS";
  arch =
    if pkgs.stdenv.isDarwin then "x86_64" else
    if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then "aarch64"
    else ""; #for plain `linux.tar.gz`
  daml = (build_daml { stdenv = pkgs.stdenv;
                       jdk = pkgs.openjdk17_headless;
                       sdkVersion = damlYaml.sdk-version;
                       damlVersion = damlYaml.daml-version;
                       tarPath = damlYaml.daml-tar-path or null;
                       curl = pkgs.curl;
                       curl_cert = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
                       os = os;
                       arch = arch;
                       osJFrog = if pkgs.stdenv.isDarwin then "macos" else "linux-intel";
                       hashes = { linux = "u6llnAHwNZk1vyt4A/0xnCvRbcp9HPWnIMAIaTPCSuI=";
                                  macos = "ox54HE1OqReu3R+uGIq3cAS0TQVtBj4IpcjR4UeAPuA="; };});
in
pkgs.mkShell {
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  buildInputs = [
    daml
    pkgs.bash
    pkgs.binutils # cp, grep, etc.
    pkgs.cacert
    pkgs.circleci-cli
    pkgs.curl
    pkgs.gh
    pkgs.git
    pkgs.gnupg
    pkgs.jq
    pkgs.python39
    pkgs.openssh
    pkgs.unixtools.xxd
    pkgs.yq-go
  ];
}
