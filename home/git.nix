_: {
  programs = {
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };

    git = {
      enable = true;

      settings = {
        user.name = "telcharr";
        user.email = "ean@dunagan.dev";

        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        rebase.autoStash = true;
        diff.algorithm = "histogram";
        merge.conflictStyle = "zdiff3";
        fetch.prune = true;
        rerere.enabled = true;

        credential."https://github.com".helper = "!gh auth git-credential";
        credential."https://gist.github.com".helper = "!gh auth git-credential";
      };

      ignores = [
        ".direnv/"
        "result"
        "result-*"
        ".envrc.local"
        "*.swp"
        ".DS_Store"
      ];
    };

    lazygit.enable = true;
  };
}
