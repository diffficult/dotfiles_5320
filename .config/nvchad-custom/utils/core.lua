local M = {}

require "custom.utils.mouse"

-- 󰞏 on
-- 󱜞 off

M.remove_mappings = function(section)
  vim.schedule(function()
    local function remove_section_map(section_values)
      if section_values.plugin then
        return
      end

      for mode, mode_values in pairs(section_values) do
        for keybind, _ in pairs(mode_values) do
          local _, _ = pcall(vim.api.nvim_del_keymap, mode, keybind)
        end
      end
    end

    local mappings = require("core.utils").load_config().mappings

    if type(section) == "string" then
      mappings[section]["plugin"] = nil
      mappings = { mappings[section] }
    end

    for _, sect in pairs(mappings) do
      remove_section_map(sect)
    end
  end)
end

function Get_Version()
  if vim.g.status_version ~= nil then
    return vim.g.status_version
  else
    return ""
  end
end

function Get_Cmp()
  if vim.g.cmptoggle == true then
    return "󰞏  "
  else
    return "󱜞  "
  end
end

function Get_npm()
  local ok, package = pcall(require, "package-info")
  if ok then
    local status = package.get_status()
    if status ~= "" then
      return "  " .. status .. " "
    end
    return ""
  else
    return ""
  end
end

function Get_dap()
  local ok, dap = pcall(require, "dap")
  if ok then
    local status = dap.status()
    if status ~= "" then
      return "   " .. status .. " "
    end
    return ""
  else
    return ""
  end
end

function Get_marked()
  local Marked = require "harpoon.mark"
  local filename = vim.api.nvim_buf_get_name(0)
  local success, index = pcall(Marked.get_index_of, filename)
  if success and index and index ~= nil then
    return "󱡀 " .. index .. " "
  else
    return ""
  end
end

function Get_record()
  local ok, recorder = pcall(require, "recorder")
  if ok then
    local status = recorder.recordingStatus()
    if status ~= "" then
      return " " .. status .. " "
    end
    return ""
  else
    return ""
  end
end

M.dapui = {
  icons = { expanded = "▾", collapsed = "▸" },
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
  },
  expand_lines = false,
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.40 },
        { id = "breakpoints", size = 0.20 },
        { id = "stacks", size = 0.20 },
        { id = "watches", size = 0.20 },
      },
      size = 40, -- 40 columns
      position = "left",
    },
    {
      elements = {
        {
          id = "repl",
          size = 0.5,
        },
        {
          id = "console",
          size = 0.5,
        },
      },
      size = 10, -- 25% of total lines
      position = "bottom",
    },
  },
  floating = {
    max_height = nil,
    max_width = nil,
    border = "rounded", -- Border style. Can be "single", "double" or "rounded"
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
  render = {
    max_type_length = nil,
  },
}

M.lazy = {
  change_detection = {
    enabled = true,
    notify = false,
  },
  concurrency = 10,
  git = {
    log = { "-8" }, -- show commits from the last 3 days
    timeout = 30, -- kill processes that take more than 2 minutes
    url_format = "https://github.com/%s.git",
    filter = true,
  },
}

M.tabufline = {
  show_numbers = false,
  enabled = true,
  lazyload = true,
  overriden_modules = function(modules)
    modules[4] = (function()
      return "%#SplitHl#%@v:lua.ClickUpdate@  %#SplitHl#%@v:lua.ClickGit@  %#SplitHl#%@v:lua.ClickRun@  %#SplitHl#%@v:lua.ClickSplit@ "
    end)()
  end,
}

M.statusline = {
  theme = "vscode_colored",
  overriden_modules = function(modules)
    modules[1] = (function()
      local st_modules = require "nvchad.statusline.vscode_colored"
      local modes = st_modules.modes
      modes["n"][3] = "  "
      modes["v"][3] = "  "
      modes["i"][3] = "  "
      modes["t"][3] = "  "
      local m = vim.api.nvim_get_mode().mode
      return "%#" .. modes[m][2] .. "#" .. (modes[m][3] or "  ") .. modes[m][1] .. " "
    end)()
    modules[2] = (function()
      local icon = " 󰈚 "
      local filename = vim.fn.expand "%:t"
      local icon_text
      if filename ~= "Empty " then
        local devicons_present, devicons = pcall(require, "nvim-web-devicons")
        if devicons_present then
          local ft_icon, ft_icon_hl = devicons.get_icon(filename, string.match(filename, "%a+$"))
          icon = (ft_icon ~= nil and " " .. ft_icon) or ""
          local icon_hl = ft_icon_hl or "DevIconDefault"
          local hl_fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(icon_hl)), "fg")
          local hl_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID "StText"), "bg")
          vim.api.nvim_set_hl(0, "St_" .. icon_hl, { fg = hl_fg, bg = hl_bg })
          if string.find(filename, "toggleterm") then
            filename = '%{&ft == "toggleterm" ? " Terminal (".b:toggle_number.") " : ""}'
          end
          if string.find(filename, "NvimTree") then
            filename = '%{&ft == "NvimTree" ? " File Explorer " : ""}'
          end
          icon_text = "%#St_" .. icon_hl .. "# " .. icon .. "%#StText# " .. filename .. " "
        end
      end
      return icon_text or ("%#StText# " .. icon .. filename)
    end)()
    table.insert(
      modules,
      4,
      (function()
        return "%#HarpoonHl#" .. Get_marked() .. Get_record()
      end)()
    )
    table.insert(
      modules,
      7,
      (function()
        return Get_dap()
        -- .. Get_npm()
      end)()
    )
    table.insert(
      modules,
      6,
      (function()
        return "%#TermHl#%@v:lua.ClickTerm@  "
      end)()
    )
--    table.insert(
--      modules,
--      16,
--      (function()
--        return "%#NotificationHl# " .. Get_Version() .. "%@v:lua.ClickMe@ " .. " %#CmpHl#" .. Get_Cmp()
--      end)()
--    )
  end,
}

M.nvdash = {
  load_on_startup = true,
  header = {
    -- [[                                                   ]],
    -- [[                                              ___  ]],
    -- [[                                           ,o88888 ]],
    -- [[                                        ,o8888888' ]],
    -- [[                  ,:o:o:oooo.        ,8O88Pd8888"  ]],
    -- [[              ,.::.::o:ooooOoOo:. ,oO8O8Pd888'"    ]],
    -- [[            ,.:.::o:ooOoOoOO8O8OOo.8OOPd8O8O"      ]],
    -- [[           , ..:.::o:ooOoOOOO8OOOOo.FdO8O8"        ]],
    -- [[          , ..:.::o:ooOoOO8O888O8O,COCOO"          ]],
    -- [[         , . ..:.::o:ooOoOOOO8OOOOCOCO"            ]],
    -- [[          . ..:.::o:ooOoOoOO8O8OCCCC"o             ]],
    -- [[             . ..:.::o:ooooOoCoCCC"o:o             ]],
    -- [[             . ..:.::o:o:,cooooCo"oo:o:            ]],
    -- [[          `   . . ..:.:cocoooo"'o:o:::'            ]],
    -- [[          .`   . ..::ccccoc"'o:o:o:::'             ]],
    -- [[         :.:.    ,c:cccc"':.:.:.:.:.'              ]],
    -- [[       ..:.:"'`::::c:"'..:.:.:.:.:.'               ]],
    -- [[     ...:.'.:.::::"'    . . . . .'                 ]],
    -- [[    .. . ....:."' `   .  . . ''                    ]],
    -- [[  . . . ...."'                                     ]],
    -- [[  .. . ."'                                         ]],
    -- [[ .                                                 ]],
    -- [[                                                   ]],

    -- "  NvChad                     ",
    -- "     ▄▄         ▄ ▄▄▄▄▄▄▄    ",
    -- "   ▄▀███▄     ▄██ █████▀     ",
    -- "   ██▄▀███▄   ███            ",
    -- "   ███  ▀███▄ ███            ",
    -- "   ███    ▀██ ███            ",
    -- "   ███      ▀ ███            ",
    -- "   ▀██ █████▄▀█▀▄██████▄     ",
    -- "     ▀ ▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀    ",
    -- "        Powered by Neovim    ",

    -- [[                @@@%%%%%%%%%@@                ]],
    -- [[              @@@%%%%%%%%%#######%@@          ]],
    -- [[            @@@@%%%%%%%######?######%@        ]],
    -- [[            @@@@%%%%%%%#######:########%@     ]],
    -- [[          @@@@@%%%%%%#########:??#######%     ]],
    -- [[          @@@%%%%%####???###?+:??####?###@    ]],
    -- [[        @@@%%%%%%#?+???###?:+?##??###?##@     ]],
    -- [[      @??%@%%%##????????++:;+?+????????#@     ]],
    -- [[      #  ;?%#?+; ..::+?+ ::;++++++?+???#      ]],
    -- [[      %  :?%;;;:  ....:#+ :;+++????+???@      ]],
    -- [[      #;;+??+++:   ...;##: ;;;++???++?%       ]],
    -- [[      %#%+::++?#+;:::;?##+ ;;;;++??++#        ]],
    -- [[      %?% : :???+?++???######?+;;+??#         ]],
    -- [[      @%# ; ;??;;+ ;???+;;:..::.:+?%          ]],
    -- [[        @???;;?+;;;+ ;:;;......;;;#@          ]],
    -- [[        %##?++?+++;+ ??% @%%@@@@              ]],
    -- [[        @_:?_:+_:_:#%                         ]],
    -- [[                                              ]],
  },
}

return M
