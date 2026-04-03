local filesystem = require("filesystem")
local serialization = require("serialization")

local runtimeService = {}

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function writeFile(path, content)
  local handle, err = io.open(path, "w")
  if not handle then
    return nil, err
  end

  handle:write(content or "")
  handle:close()
  return true
end

function runtimeService.create(root)
  local service = {
    root = root or "/aeon/runtime",
    state = {
      session = {},
      notifications = {}
    }
  }

  function service:init()
    ensureDir(self.root)
    ensureDir(filesystem.concat(self.root, "cache"))
    ensureDir(filesystem.concat(self.root, "locks"))
    ensureDir(filesystem.concat(self.root, "notifications"))
    return true
  end

  function service:setSession(session)
    self.state.session = session or {}
    return self:flush()
  end

  function service:getSession()
    return self.state.session
  end

  function service:pushNotification(message, level)
    table.insert(self.state.notifications, {
      message = tostring(message or ""),
      level = level or "info"
    })
    return self:flush()
  end

  function service:getNotifications()
    return self.state.notifications
  end

  function service:flush()
    self:init()
    local path = filesystem.concat(self.root, "session.db")
    return writeFile(path, serialization.serialize(self.state))
  end

  return service
end

return runtimeService
