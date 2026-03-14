{ pkgs, ... }:
{
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
    shell = pkgs.bashInteractive;
  };
}
