{ pkgs, ... }:
let
  dev = pkgs.writeShellApplication {
    name = "dev";
    runtimeInputs = with pkgs; [
      direnv
      nix
      python3
      findutils
      gnugrep
      coreutils
    ];
    text = builtins.readFile ../scripts/dev.sh;
  };

  devCompletion = pkgs.runCommand "dev-zsh-completion" { } ''
    mkdir -p "$out/share/zsh/site-functions"
    cp ${../scripts/_dev} "$out/share/zsh/site-functions/_dev"
  '';
in
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    config.global.warn_timeout = "0s";
  };

  home.packages = [
    dev
    devCompletion
  ];
}
