_: {
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 50000;
        save = 50000;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = true;
        extended = true;
      };

      shellAliases = {
        ll = "eza -l --git --group-directories-first";
        la = "eza -la --git --group-directories-first";
        cat = "bat --paging=never";
        ".." = "cd ..";
        hm = "git -C ~/dotfiles add -A && home-manager switch --flake ~/dotfiles#telcharr";
        hm-news = "home-manager news --flake ~/dotfiles#telcharr";
        hm-gens = "home-manager generations";
        update = "paru";
      };

      initContent = ''
        export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
        bindkey -e
        bindkey "''${terminfo[kcuu1]:-^[[A}" history-beginning-search-backward
        bindkey "''${terminfo[kcud1]:-^[[B}" history-beginning-search-forward
      '';
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        add_newline = true;
        format = builtins.concatStringsSep "" [
          "$directory"
          "$git_branch"
          "$git_status"
          "$nix_shell"
          "$direnv"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        directory = {
          style = "bold #9e9e9e";
          truncation_length = 3;
          truncate_to_repo = true;
          truncation_symbol = "…/";
          format = "[$path]($style) ";
        };

        git_branch = {
          style = "#4a4a4a";
          format = "[$branch]($style) ";
        };

        git_status = {
          style = "#ff5c00";
          format = "[$all_status$ahead_behind]($style) ";
          conflicted = "~";
          ahead = "↑\${count}";
          behind = "↓\${count}";
          diverged = "↕";
          untracked = "?";
          stashed = "\$";
          modified = "!";
          staged = "+";
          renamed = "»";
          deleted = "x";
        };

        nix_shell = {
          style = "#ff5c00";
          format = "[nix]($style) ";
          heuristic = true;
        };

        direnv = {
          disabled = false;
          style = "#4a4a4a";
          format = "[env]($style) ";
          allowed_msg = "";
          not_allowed_msg = "!";
          denied_msg = "x";
          loaded_msg = "";
          unloaded_msg = "-";
        };

        cmd_duration = {
          min_time = 2000;
          style = "#4a4a4a";
          format = "[$duration]($style) ";
        };

        character = {
          success_symbol = "[❯](#ff5c00)";
          error_symbol = "[❯](#c25c40)";
          vimcmd_symbol = "[❮](#ff5c00)";
        };
      };
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    bat.enable = true;
    eza.enable = true;
  };
}
