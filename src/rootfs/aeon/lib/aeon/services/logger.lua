local filesystem = require("filesystem")

local loggerService = {}

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function appendLine(path, line)
  local handle = io.open(path, "a")
  if not handle then
    return nil
  end

  handle:write(line .. "\n")
  handle:close()
  return true
end

function loggerService.create(root)
  local service = {
    root = root or "/aeon/runtime/logs",
    fileName = "aeon.log"
  }

  function service:init()
    ensureDir(self.root)
  end

  function service:write(level, message)
    self:init()
    local line = string.format("[%s] %s", tostring(level or "INFO"), tostring(message or ""))
    local path = filesystem.concat(self.root, self.fileName)
    appendLine(path, line)
  end

  function service:info(message)
    self:write("INFO", message)
  end

  function service:error(message)
    self:write("ERROR", message)
  end

  return service
end

return loggerService
