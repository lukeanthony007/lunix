{ inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
    ];
    enabledCustomApps = with spicePkgs.apps; [
      marketplace
    ];
    theme = {
      name = "Lucid";
      src = pkgs.fetchFromGitHub {
        owner = "sanoojes";
        repo = "Spicetify-Lucid";
        rev = "3746c1eb8cdda4d5b680dcc769ad629b467a4520";
        hash = "sha256-ciA3LptZeflCwkUq66E2ZCvxpLH8/XVJyMimjdU9Fk0=";
      } + "/src";
      injectCss = true;
      injectThemeJs = true;
      replaceColors = true;
    };
  };
}
