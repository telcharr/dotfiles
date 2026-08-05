vim.cmd.highlight("clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd.syntax("reset")
end
vim.g.colors_name = "ember"
vim.o.background = "dark"

local p = {
  bg0 = "#0e0e0e",
  bg1 = "#171717",
  bg2 = "#1f1f1f",
  bg3 = "#2a2a2a",
  gray0 = "#4a4a4a",
  gray1 = "#6e6e6e",
  gray2 = "#8a8a8a",
  gray3 = "#9e9e9e",
  fg0 = "#d4d4d4",
  fg1 = "#f0f0f0",
  accent = "#ff5c00",
  accent_dim = "#c24600",
  red = "#c25c40",
  green = "#778a68",

  kw = "#cf7a4a",
  fn = "#e2a961",
  str = "#8f9e7d",
  num = "#c98a9b",
  ty = "#bfa583",
  const = "#dcb06a",
  mem = "#bfc4c9",
  cmt = "#565656",
}

local hl = function(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local groups = {
  Normal = { fg = p.fg0, bg = p.bg0 },
  NormalFloat = { fg = p.fg0, bg = p.bg1 },
  FloatBorder = { fg = p.bg3, bg = p.bg1 },
  FloatTitle = { fg = p.accent, bg = p.bg1, bold = true },
  Cursor = { fg = p.bg0, bg = p.accent },
  CursorLine = { bg = p.bg1 },
  CursorLineNr = { fg = p.accent },
  LineNr = { fg = p.gray0 },
  SignColumn = { bg = p.bg0 },
  ColorColumn = { bg = p.bg1 },
  VertSplit = { fg = p.bg2 },
  WinSeparator = { fg = p.bg2 },
  Folded = { fg = p.gray1, bg = p.bg1 },
  Visual = { bg = p.bg3 },
  Search = { fg = p.bg0, bg = p.gray2 },
  IncSearch = { fg = p.bg0, bg = p.accent },
  CurSearch = { fg = p.bg0, bg = p.accent },
  MatchParen = { fg = p.accent, bold = true },
  Pmenu = { fg = p.gray2, bg = p.bg1 },
  PmenuSel = { fg = p.fg1, bg = p.bg3 },
  PmenuSbar = { bg = p.bg1 },
  PmenuThumb = { bg = p.gray0 },
  StatusLine = { fg = p.gray2, bg = p.bg1 },
  StatusLineNC = { fg = p.gray0, bg = p.bg1 },
  TabLine = { fg = p.gray0, bg = p.bg1 },
  TabLineSel = { fg = p.accent, bg = p.bg0 },
  TabLineFill = { bg = p.bg1 },
  WinBar = { fg = p.gray2, bg = p.bg0 },
  WinBarNC = { fg = p.gray0, bg = p.bg0 },
  Title = { fg = p.fg1, bold = true },
  Directory = { fg = p.gray3 },
  NonText = { fg = p.bg3 },
  Whitespace = { fg = p.bg3 },
  EndOfBuffer = { fg = p.bg0 },
  QuickFixLine = { bg = p.bg2 },
  WildMenu = { fg = p.bg0, bg = p.accent },

  Comment = { fg = p.cmt, italic = true },
  Constant = { fg = p.const },
  String = { fg = p.str },
  Character = { fg = p.str },
  Number = { fg = p.num },
  Boolean = { fg = p.num },
  Float = { fg = p.num },
  Identifier = { fg = p.fg0 },
  Function = { fg = p.fn, bold = true },
  Statement = { fg = p.kw },
  Conditional = { fg = p.kw },
  Repeat = { fg = p.kw },
  Label = { fg = p.kw },
  Operator = { fg = p.gray1 },
  Keyword = { fg = p.kw },
  Exception = { fg = p.accent },
  PreProc = { fg = p.kw },
  Include = { fg = p.kw },
  Define = { fg = p.kw },
  Macro = { fg = p.accent },
  Type = { fg = p.ty },
  StorageClass = { fg = p.kw },
  Structure = { fg = p.ty },
  Typedef = { fg = p.ty },
  Special = { fg = p.accent },
  SpecialChar = { fg = p.accent },
  Delimiter = { fg = p.gray1 },
  Underlined = { underline = true },
  Error = { fg = p.red },
  Todo = { fg = p.bg0, bg = p.accent, bold = true },

  DiffAdd = { fg = p.green, bg = p.bg1 },
  DiffChange = { fg = p.gray2, bg = p.bg1 },
  DiffDelete = { fg = p.red, bg = p.bg1 },
  DiffText = { fg = p.fg1, bg = p.bg2 },
  Added = { fg = p.green },
  Changed = { fg = p.gray2 },
  Removed = { fg = p.red },

  DiagnosticError = { fg = p.red },
  DiagnosticWarn = { fg = p.accent },
  DiagnosticInfo = { fg = p.gray2 },
  DiagnosticHint = { fg = p.gray1 },
  DiagnosticOk = { fg = p.green },
  DiagnosticUnderlineError = { undercurl = true, sp = p.red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = p.accent },
  DiagnosticUnderlineInfo = { undercurl = true, sp = p.gray2 },
  DiagnosticUnderlineHint = { undercurl = true, sp = p.gray1 },

  LspReferenceText = { bg = p.bg2 },
  LspReferenceRead = { bg = p.bg2 },
  LspReferenceWrite = { bg = p.bg2, underline = true },
  LspInlayHint = { fg = p.gray0, bg = p.bg1 },

  ["@variable"] = { fg = p.fg0 },
  ["@variable.builtin"] = { fg = p.mem, italic = true },
  ["@variable.parameter"] = { fg = p.mem },
  ["@variable.member"] = { fg = p.mem },
  ["@constant"] = { fg = p.const },
  ["@constant.builtin"] = { fg = p.const, bold = true },
  ["@module"] = { fg = p.ty },
  ["@string"] = { fg = p.str },
  ["@string.escape"] = { fg = p.accent },
  ["@string.special"] = { fg = p.accent },
  ["@number"] = { fg = p.num },
  ["@boolean"] = { fg = p.num },
  ["@function"] = { fg = p.fn, bold = true },
  ["@function.call"] = { fg = p.fn },
  ["@function.builtin"] = { fg = p.fn },
  ["@function.method"] = { fg = p.fn, bold = true },
  ["@function.method.call"] = { fg = p.fn },
  ["@constructor"] = { fg = p.ty },
  ["@keyword"] = { fg = p.kw },
  ["@keyword.function"] = { fg = p.kw },
  ["@keyword.operator"] = { fg = p.kw },
  ["@keyword.conditional"] = { fg = p.kw },
  ["@keyword.repeat"] = { fg = p.kw },
  ["@keyword.import"] = { fg = p.kw },
  ["@keyword.return"] = { fg = p.accent },
  ["@keyword.exception"] = { fg = p.accent },
  ["@type"] = { fg = p.ty },
  ["@type.builtin"] = { fg = p.ty },
  ["@attribute"] = { fg = p.gray1 },
  ["@property"] = { fg = p.mem },
  ["@punctuation"] = { fg = p.gray1 },
  ["@punctuation.bracket"] = { fg = p.gray1 },
  ["@punctuation.delimiter"] = { fg = p.gray1 },
  ["@comment"] = { fg = p.cmt, italic = true },
  ["@comment.todo"] = { fg = p.bg0, bg = p.accent, bold = true },
  ["@comment.warning"] = { fg = p.bg0, bg = p.accent },
  ["@comment.error"] = { fg = p.bg0, bg = p.red },
  ["@markup.heading"] = { fg = p.fg1, bold = true },
  ["@markup.link"] = { fg = p.accent, underline = true },
  ["@markup.raw"] = { fg = p.gray3 },
  ["@markup.list"] = { fg = p.accent },
  ["@diff.plus"] = { fg = p.green },
  ["@diff.minus"] = { fg = p.red },

  StlMode = { fg = p.bg0, bg = p.accent, bold = true },
  StlModeSep = { fg = p.accent, bg = p.bg1 },
  StlPath = { fg = p.fg0, bg = p.bg1 },
  StlAccent = { fg = p.accent, bg = p.bg1 },
  StlDim = { fg = p.gray1, bg = p.bg1 },
  StlPos = { fg = p.gray3, bg = p.bg1 },
  StlAdd = { fg = p.green, bg = p.bg1 },
  StlChange = { fg = p.gray2, bg = p.bg1 },
  StlDelete = { fg = p.red, bg = p.bg1 },
  StlError = { fg = p.red, bg = p.bg1 },
  StlWarn = { fg = p.accent, bg = p.bg1 },
  StlInfo = { fg = p.gray2, bg = p.bg1 },
  StlHint = { fg = p.gray1, bg = p.bg1 },

  GitSignsAdd = { fg = p.green },
  GitSignsChange = { fg = p.gray2 },
  GitSignsDelete = { fg = p.red },
  GitSignsUntracked = { fg = p.gray0 },

  FzfLuaBorder = { fg = p.bg3, bg = p.bg1 },
  FzfLuaTitle = { fg = p.accent, bg = p.bg1, bold = true },
  FzfLuaNormal = { fg = p.fg0, bg = p.bg1 },
  FzfLuaCursorLine = { fg = p.fg1, bg = p.bg3 },
  FzfLuaFzfMatch = { fg = p.accent },
  FzfLuaPathLineNr = { fg = p.gray0 },
  FzfLuaPathColNr = { fg = p.gray0 },

  OilDir = { fg = p.gray3 },
  OilFile = { fg = p.fg0 },
  OilCreate = { fg = p.green },
  OilDelete = { fg = p.red },
  OilChange = { fg = p.accent },
}

for group, opts in pairs(groups) do
  hl(group, opts)
end

vim.g.terminal_color_0 = p.bg1
vim.g.terminal_color_1 = "#a04a32"
vim.g.terminal_color_2 = "#5f7052"
vim.g.terminal_color_3 = p.accent
vim.g.terminal_color_4 = "#5a5a5a"
vim.g.terminal_color_5 = p.gray1
vim.g.terminal_color_6 = "#828282"
vim.g.terminal_color_7 = p.fg0
vim.g.terminal_color_8 = p.bg3
vim.g.terminal_color_9 = p.red
vim.g.terminal_color_10 = p.green
vim.g.terminal_color_11 = "#ff7a2e"
vim.g.terminal_color_12 = "#757575"
vim.g.terminal_color_13 = p.gray2
vim.g.terminal_color_14 = p.gray3
vim.g.terminal_color_15 = p.fg1
