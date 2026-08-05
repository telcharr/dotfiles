vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  float = { border = "single", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

local servers = {
  nixd = "nixd",
  rust_analyzer = "rust-analyzer",
  gopls = "gopls",
  clangd = "clangd",
  basedpyright = "basedpyright-langserver",
  ruff = "ruff",
  lua_ls = "lua-language-server",
  bashls = "bash-language-server",
  taplo = "taplo",
}

vim.lsp.config("nixd", {
  settings = {
    nixd = {
      formatting = { command = { "nixfmt" } },
    },
  },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        path = { "?.lua", "?/init.lua" },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
        },
      },
      diagnostics = { globals = { "vim" } },
      hint = { enable = true },
      telemetry = { enable = false },
    },
  },
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = "standard" },
    },
  },
})

local enabled = {}
for name, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then
    vim.lsp.enable(name)
    enabled[#enabled + 1] = name
  end
end

vim.api.nvim_create_user_command("LspActive", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("no LSP attached; enabled: " .. (table.concat(enabled, ", ")))
    return
  end
  local names = vim.tbl_map(function(c)
    return c.name
  end, clients)
  vim.notify("attached: " .. table.concat(names, ", "))
end, { desc = "Show attached LSP clients" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(args)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
    end
    local fzf = require("fzf-lua")

    map("n", "grn", vim.lsp.buf.rename, "Rename")
    map({ "n", "v" }, "gra", vim.lsp.buf.code_action, "Code action")
    map("n", "grr", fzf.lsp_references, "References")
    map("n", "gri", fzf.lsp_implementations, "Implementations")
    map("n", "gd", fzf.lsp_definitions, "Definition")
    map("n", "gD", vim.lsp.buf.declaration, "Declaration")
    map("n", "gy", fzf.lsp_typedefs, "Type definition")
    map("n", "gO", fzf.lsp_document_symbols, "Document symbols")
    map("n", "K", function()
      vim.lsp.buf.hover({ border = "single" })
    end, "Hover")
    map("i", "<C-s>", function()
      vim.lsp.buf.signature_help({ border = "single" })
    end, "Signature help")

    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    if client and client:supports_method("textDocument/inlayHint") then
      map("n", "<leader>ti", function()
        local on = vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf })
        vim.lsp.inlay_hint.enable(not on, { bufnr = args.buf })
      end, "Toggle inlay hints")
    end
  end,
})
