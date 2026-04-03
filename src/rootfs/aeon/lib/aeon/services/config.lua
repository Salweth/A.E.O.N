local filesystem = require("filesystem")
local serialization = require("serialization")

local configService = {}

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function readFile(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil
  end

  local data = handle:read("*a")
  handle:close()
  return data
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

function configService.create(root)
  local service = {
    root = root or "/aeon/config",
    fileName = "system.cfg"
  }

  function service:init()
    ensureDir(self.root)
    local path = filesystem.concat(self.root, self.fileName)
    if filesystem.exists(path) then
      return true
    end

    local defaultConfig = {
      installVersion = "2.0.0-alpha",
      workstation = {
        id = "unknown-workstation",
        role = "field-agent"
      },
      agent = {
        name = "unassigned",
        clearance = "standard"
      }
    }

    return writeFile(path, serialization.serialize(defaultConfig))
  end

  function service:getAll()
    self:init()
    local path = filesystem.concat(self.root, self.fileName)
    local raw = readFile(path)
    if not raw or raw == "" then
      return {}
    end

    local ok, data = pcall(serialization.unserialize, raw)
    if not ok or type(data) ~= "table" then
      return {}
    end

    return data
  end

  function service:get(key)
    local data = self:getAll()
    return data[key]
  end

  return service
end

return configService
