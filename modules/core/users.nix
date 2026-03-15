{ pkgs, ... }:
{
  programs.fish.enable = true;
  users.mutableUsers = true;

  users.users.luke = {
    isNormalUser = true;
    description = "Luke";
    extraGroups = [
      "audio"
      "docker"
      "networkmanager"
      "video"
      "wheel"
    ];
    initialPassword = "luke";
    shell = pkgs.fish;
  };
}
