{
  nodejs,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    biome
    nodejs
    pnpm
    typescript-language-server
    vscode-langservers-extracted
  ];
}
