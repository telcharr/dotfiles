local M = {}

local modes = {
  n = "normal",
  no = "op",
  v = "visual",
  V = "v-line",
  ["\22"] = "v-block",
  s = "select",
  S = "s-line",
  ["\19"] = "s-block",
  i = "insert",
  ic = "insert",
  R = "replace",
  Rv = "v-replace",
  c = "command",
  cv = "ex",
  r = "prompt",
  rm = "more",
  ["r?"] = "confirm",
  ["!"] = "shell",
  t = "terminal",
}

local function mode()
  local m = modes[vim.api.nvim_get_mode().mode] or "?"
  return "%#StlMode# " .. m .. " %#StlModeSep#%*"
end

local function path()
  local name = vim.fn.expand("%:~:.")
  if name == "" then
    return "%#StlDim# [no name] %*"
  end
  local flag = vim.bo.modified and "%#StlAccent# + %*" or ""
  local ro = vim.bo.readonly and "%#StlDim# ro%*" or ""
  return "%#StlPath# " .. name .. "%*" .. flag .. ro
end

local function branch()
  local head = vim.b.gitsigns_head
  if not head or head == "" then
    return ""
  end
  return "%#StlDim# " .. head .. " %*"
end

local function diff()
  local d = vim.b.gitsigns_status_dict
  if not d then
    return ""
  end
  local out = {}
  if (d.added or 0) > 0 then
    out[#out + 1] = "%#StlAdd#+" .. d.added .. "%*"
  end
  if (d.changed or 0) > 0 then
    out[#out + 1] = "%#StlChange#~" .. d.changed .. "%*"
  end
  if (d.removed or 0) > 0 then
    out[#out + 1] = "%#StlDelete#-" .. d.removed .. "%*"
  end
  if #out == 0 then
    return ""
  end
  return " " .. table.concat(out, " ") .. " "
end

local function diagnostics()
  local counts = { 0, 0, 0, 0 }
  for _, d in ipairs(vim.diagnostic.get(0)) do
    counts[d.severity] = counts[d.severity] + 1
  end
  local out = {}
  local groups = { "StlError", "StlWarn", "StlInfo", "StlHint" }
  local labels = { "E", "W", "I", "H" }
  for i = 1, 4 do
    if counts[i] > 0 then
      out[#out + 1] = "%#" .. groups[i] .. "#" .. labels[i] .. counts[i] .. "%*"
    end
  end
  if #out == 0 then
    return ""
  end
  return " " .. table.concat(out, " ") .. " "
end

local function lsp()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    return ""
  end
  local names = {}
  for _, c in ipairs(clients) do
    names[#names + 1] = c.name
  end
  return "%#StlDim# " .. table.concat(names, ",") .. " %*"
end

local function filetype()
  local ft = vim.bo.filetype
  if ft == "" then
    return ""
  end
  return "%#StlDim# " .. ft .. " %*"
end

local function position()
  return "%#StlPos# %l:%c %#StlDim#%P %*"
end

function M.render()
  return table.concat({
    mode(),
    branch(),
    path(),
    diff(),
    "%=",
    diagnostics(),
    lsp(),
    filetype(),
    position(),
  })
end

vim.o.statusline = "%!v:lua.require'statusline'.render()"

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "LspAttach", "LspDetach", "User" }, {
  group = vim.api.nvim_create_augroup("statusline", { clear = true }),
  callback = function()
    vim.cmd.redrawstatus()
  end,
})

return M
