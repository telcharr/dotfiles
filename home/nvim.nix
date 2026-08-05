{ pkgs, ... }:
let
  site = ".local/share/nvim/site/pack/nix/start";

  grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
    nix
    rust
    go
    gomod
    gosum
    python
    c
    cpp
    cmake
    bash
    lua
    json
    toml
    yaml
    sql
    markdown
    markdown_inline
    vim
    vimdoc
    query
    git_config
    gitcommit
    git_rebase
    gitignore
    diff
    dockerfile
    html
    css
    javascript
    typescript
    regex
    comment
    just
  ];

  treesitterRuntime = pkgs.symlinkJoin {
    name = "nvim-treesitter-runtime";
    paths = grammars ++ [ "${pkgs.vimPlugins.nvim-treesitter}/runtime" ];
  };
in
{
  home.file = {
    "${site}/nvim-treesitter".source = pkgs.vimPlugins.nvim-treesitter;
    "${site}/treesitter-runtime".source = treesitterRuntime;
    "${site}/nvim-lspconfig".source = pkgs.vimPlugins.nvim-lspconfig;
    "${site}/fzf-lua".source = pkgs.vimPlugins.fzf-lua;
    "${site}/gitsigns.nvim".source = pkgs.vimPlugins.gitsigns-nvim;
    "${site}/oil.nvim".source = pkgs.vimPlugins.oil-nvim;
    "${site}/conform.nvim".source = pkgs.vimPlugins.conform-nvim;
  };
}
