package.path = package.path .. ";/aeon/lib/?.lua;/aeon/lib/?/init.lua"

local launcher = require("aeon.core.launcher")

return {
  run = function()
    launcher.run()
  end
}
