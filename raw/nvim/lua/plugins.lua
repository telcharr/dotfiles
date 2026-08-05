local map = vim.keymap.set

require("nvim-treesitter").setup({})

local fzf = require("fzf-lua")

fzf.setup({
  "borderless",
  fzf_colors = true,
  winopts = {
    height = 0.80,
    width = 0.85,
    row = 0.40,
    border = "single",
    preview = {
      layout = "vertical",
      vertical = "down:50%",
      scrollbar = false,
    },
  },
  files = { formatter = "path.filename_first" },
  grep = { rg_glob = true },
})

map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fh", fzf.helptags, { desc = "Help tags" })
map("n", "<leader>fr", fzf.resume, { desc = "Resume picker" })
map("n", "<leader>fd", fzf.diagnostics_workspace, { desc = "Workspace diagnostics" })
map("n", "<leader>fc", fzf.git_commits, { desc = "Git commits" })
map("n", "<leader>fs", fzf.git_status, { desc = "Git status" })
map("n", "<leader>/", fzf.blines, { desc = "Search buffer lines" })
map("n", "<leader><leader>", fzf.files, { desc = "Find files" })

require("gitsigns").setup({
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
    untracked = { text = "┆" },
  },
  signcolumn = true,
  current_line_blame = false,
  current_line_blame_opts = { delay = 400, virt_text_pos = "eol" },
  preview_config = { border = "single" },
  on_attach = function(buf)
    local gs = require("gitsigns")
    local opts = function(desc)
      return { buffer = buf, desc = desc }
    end

    map("n", "]h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gs.nav_hunk("next")
      end
    end, opts("Next hunk"))

    map("n", "[h", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gs.nav_hunk("prev")
      end
    end, opts("Previous hunk"))

    map("n", "<leader>hs", gs.stage_hunk, opts("Stage hunk"))
    map("n", "<leader>hr", gs.reset_hunk, opts("Reset hunk"))
    map("n", "<leader>hp", gs.preview_hunk, opts("Preview hunk"))
    map("n", "<leader>hb", gs.blame_line, opts("Blame line"))
    map("n", "<leader>hd", gs.diffthis, opts("Diff this"))
    map("n", "<leader>tb", gs.toggle_current_line_blame, opts("Toggle line blame"))
  end,
})

require("oil").setup({
  default_file_explorer = true,
  columns = { "icon" },
  skip_confirm_for_simple_edits = true,
  view_options = { show_hidden = true },
  float = { border = "single" },
  keymaps = {
    ["<Esc>"] = { "actions.close", mode = "n" },
  },
})

map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
map("n", "<leader>e", "<cmd>Oil<CR>", { desc = "File explorer" })

local conform = require("conform")

conform.setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
    lua = { lsp_format = "fallback" },
    python = { "ruff_organize_imports", "ruff_format" },
    go = { "gofmt" },
    rust = { "rustfmt", lsp_format = "fallback" },
    sql = { "sqlfluff" },
    json = { "jq" },
    sh = { "shfmt" },
    ["_"] = { lsp_format = "fallback" },
  },
  format_on_save = function(buf)
    if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
      return nil
    end
    return { timeout_ms = 1500, lsp_format = "fallback" }
  end,
})

vim.api.nvim_create_user_command("FormatToggle", function(args)
  if args.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify("buffer autoformat " .. (vim.b.disable_autoformat and "off" or "on"))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify("global autoformat " .. (vim.g.disable_autoformat and "off" or "on"))
  end
end, { bang = true, desc = "Toggle format on save" })

map("n", "<leader>tf", "<cmd>FormatToggle<CR>", { desc = "Toggle format on save" })
map("n", "<leader>tF", "<cmd>FormatToggle!<CR>", { desc = "Toggle format on save (buffer)" })

map({ "n", "v" }, "<leader>f", function()
  conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })
