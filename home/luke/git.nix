{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Luke Anthony";
    userEmail = "ln64.ohio@gmail.com";
    ignores = [
      "**/.claude/settings.local.json"
    ];
    extraConfig = {
      init.defaultBranch = "main";
      credential."https://github.com".helper = "!/usr/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!/usr/bin/gh auth git-credential";
    };
  };
}
