local M = {}

local function raw_dispatch(name, args)
  local cmd = "hyprctl dispatch " .. name
  if args and args ~= "" then
    cmd = cmd .. " " .. args
  end
  return hl.dsp.exec_cmd(cmd)
end

local function numeric_workspace(args)
  local id = tonumber(args)
  if id then
    return id
  end
  return nil
end

local function xy_args(args)
  local x, y = tostring(args or ""):match("^%s*([%-0-9]+)%s+([%-0-9]+)%s*$")
  if x and y then
    return tonumber(x), tonumber(y)
  end
  return nil, nil
end

local function resize_active(args)
  local x, y = xy_args(args)
  if not x or not y then
    return hl.dsp.no_op()
  end

  return function()
    hl.dispatch(hl.dsp.window.resize({ x = x, y = y, relative = true }))
  end
end

local function action(dispatcher, args)
  if type(dispatcher) == "function" then
    return dispatcher
  end

  args = args or ""
  if dispatcher == "exec" then
    return hl.dsp.exec_cmd(args)
  end
  if dispatcher == "submap" then
    return hl.dsp.submap(args)
  end
  if dispatcher == "workspace" then
    local id = numeric_workspace(args)
    if id then
      return hl.dsp.focus({ workspace = id })
    end
    return hl.dsp.focus({ workspace = args })
  end
  if dispatcher == "movetoworkspace" then
    local id = numeric_workspace(args)
    if id then
      return hl.dsp.window.move({ workspace = id })
    end
    if args == "special" then
      return hl.dsp.window.move({ workspace = "special" })
    end
    return hl.dsp.no_op()
  end
  if dispatcher == "togglespecialworkspace" then
    return hl.dsp.workspace.toggle_special(args ~= "" and args or nil)
  end
  if dispatcher == "killactive" then
    return hl.dsp.window.close({})
  end
  if dispatcher == "centerwindow" then
    return hl.dsp.window.center({})
  end
  if dispatcher == "pin" then
    return hl.dsp.window.pin({ action = "toggle" })
  end
  if dispatcher == "cyclenext" then
    return hl.dsp.window.cycle_next({})
  end
  if dispatcher == "movefocus" then
    return hl.dsp.focus({ direction = args })
  end
  if dispatcher == "movewindow" then
    if args == "" then
      return hl.dsp.window.drag()
    end
    return hl.dsp.window.move({ direction = args })
  end
  if dispatcher == "layoutmsg" then
    return hl.dsp.layout(args)
  end
  if dispatcher == "fullscreen" then
    return hl.dsp.window.fullscreen({ mode = tonumber(args) or 0 })
  end
  if dispatcher == "pseudo" then
    return hl.dsp.window.pseudo({ action = "toggle" })
  end
  if dispatcher == "togglefloating" then
    return hl.dsp.window.float({ action = "toggle" })
  end
  if dispatcher == "resizeactive" then
    return resize_active(args)
  end
  if dispatcher == "resizewindow" then
    return hl.dsp.window.resize()
  end
  return raw_dispatch(dispatcher, args)
end

local function normalize_flags(flags)
  flags = flags or {}
  if flags.repeatable ~= nil then
    flags.repeating = flags.repeatable
    flags.repeatable = nil
  end
  return flags
end

function M.bind(keys, dispatcher, args, flags)
  hl.bind(keys, action(dispatcher, args), normalize_flags(flags))
end

function M.submap(name, fn)
  hl.define_submap(name, fn)
end

return M
