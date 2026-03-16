{ pkgs, applianceUser ? "luke", ... }:
{
  programs.fish.enable = true;
  users.mutableUsers = true;

  users.users.${applianceUser} = {
    isNormalUser = true;
    description = applianceUser;
    extraGroups = [
      "audio"
      "docker"
      "networkmanager"
      "video"
      "wheel"
    ];
    initialPassword = applianceUser;
    shell = pkgs.fish;
  };
}
