local root = os.getenv("HOME") .. "/.config/hypr"
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

require("core.monitors")
require("core.env")
require("core.general")
require("core.autostart")
require("core.rules")
require("core.keybindings")
require("integrations.warmind_launcher")
