---@type ChadrcConfig
local M = {}

local core = require "custom.utils.core"

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
 theme = "tokyonight",
 theme_toggle = { "tokyonight", "one_light" },
 lsp_semantic_tokens = false,
 statusline = core.statusline,
 tabufline = core.tabufline,

 cmp = {
   icons = true,
   lspkind_text = true,
   style = "default", -- default/flat_light/flat_dark/atom/atom_colored
   border_color = "grey_fg", -- only applicable for "default" style, use color names from base30 variables
   selected_item_bg = "colored", -- colored / simple
 },

 lsp = {
   signature = false,
 },

 telescope = { style = "bordered" },

 extended_integrations = {
   "dap",
   "hop",
   "rainbowdelimiters",
   "codeactionmenu",
   "todo",
   "trouble",
   "notify",
 },

 hl_override = highlights.override,
 hl_add = highlights.add,

--  nvdash = core.nvdash,

-- nvdash (dashboard)
 nvdash = {
   load_on_startup = true,

   header = {
  	[[                                                     ]],
  	[[  ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓ ]],
  	[[  ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒ ]],
  	[[ ▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░ ]],
  	[[ ▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██  ]],
  	[[ ▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒ ]],
  	[[ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░ ]],
  	[[ ░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░ ]],
  	[[    ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░    ]],
  	[[          ░    ░  ░    ░ ░        ░   ░         ░    ]],
  	[[                                 ░                   ]],
  	[[                                                     ]],
   },

   buttons = {
     { "  Find File", "Spc f f", "Telescope find_files" },
     { "󰈚  Recent Files", "Spc f o", "Telescope oldfiles" },
     { "󰈭  Find Word", "Spc f w", "Telescope live_grep" },
     { "  Bookmarks", "Spc m a", "Telescope marks" },
     { "  Themes", "Spc t h", "Telescope themes" },
     { "  Mappings", "Spc c h", "NvCheatsheet" },
   },
 },

}

M.settings = {
  cc_size = "130",
  so_size = 10,

  -- Blacklisted files where cc and so must be disabled
  blacklist = {
    "NvimTree",
    "nvdash",
    "nvcheatsheet",
    "terminal",
    "Trouble",
    "help",
  },
}

M.lazy_nvim = core.lazy

M.gitsigns = {
  signs = {
    add = { text = " " },
    change = { text = " " },
    delete = { text = " " },
    topdelete = { text = " " },
    changedelete = { text = " " },
    untracked = { text = " " },
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
