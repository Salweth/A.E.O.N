local filesystem = require("filesystem")
local serialization = require("serialization")

local appsService = {}

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

function appsService.create(configRoot)
  local service = {
    configRoot = configRoot or "/aeon/config",
    fileName = "apps.cfg",
    state = {
      apps = {}
    }
  }

  function service:path()
    return filesystem.concat(self.configRoot, self.fileName)
  end

  function service:init()
    ensureDir(self.configRoot)
    if filesystem.exists(self:path()) then
      return self:load()
    end
    return self:save()
  end

  function service:load()
    local raw = readFile(self:path())
    if not raw or raw == "" then
      self.state = {apps = {}}
      return self.state
    end

    local ok, data = pcall(serialization.unserialize, raw)
    if not ok or type(data) ~= "table" then
      self.state = {apps = {}}
      return self.state
    end

    if type(data.apps) ~= "table" then
      data.apps = {}
    end

    self.state = data
    return self.state
  end

  function service:save()
    ensureDir(self.configRoot)
    return writeFile(self:path(), serialization.serialize(self.state))
  end

  function service:syncCatalog(catalog)
    self:init()

    for appId, manifest in pairs(catalog or {}) do
      if not manifest.invalid then
        local current = self.state.apps[appId]
        if not current then
          local defaultInstalled = manifest.defaultInstalled ~= false
          self.state.apps[appId] = {
            installed = defaultInstalled,
            enabled = defaultInstalled
          }
        end
      end
    end

    return self:save()
  end

  function service:getState(appId)
    self:init()
    return self.state.apps[appId]
  end

  function service:isLaunchable(appId, manifest)
    local current = self:getState(appId)
    if not manifest or manifest.invalid then
      return false
    end
    if not current then
      return manifest.defaultInstalled ~= false
    end
    return current.installed == true and current.enabled == true
  end

  function service:toggleEnabled(appId)
    self:init()
    local current = self.state.apps[appId]
    if not current then
      current = {
        installed = true,
        enabled = true
      }
      self.state.apps[appId] = current
    end

    current.installed = true
    current.enabled = not (current.enabled == true)
    local ok, err = self:save()
    if not ok then
      return nil, err
    end

    return current.enabled
  end

  function service:listCatalog(catalog)
    self:init()
    local items = {}

    for appId, manifest in pairs(catalog or {}) do
      if not manifest.invalid then
        local state = self.state.apps[appId] or {
          installed = manifest.defaultInstalled ~= false,
          enabled = manifest.defaultInstalled ~= false
        }

        table.insert(items, {
          id = appId,
          name = manifest.name or appId,
          category = manifest.category or "misc",
          defaultInstalled = manifest.defaultInstalled ~= false,
          installed = state.installed == true,
          enabled = state.enabled == true
        })
      end
    end

    table.sort(items, function(a, b)
      return a.name < b.name
    end)

    return items
  end

  function service:listLaunchable(catalog)
    local items = {}
    for appId, manifest in pairs(catalog or {}) do
      if self:isLaunchable(appId, manifest) then
        table.insert(items, manifest)
      end
    end

    table.sort(items, function(a, b)
      local orderA = a.launcher and a.launcher.order or 999
      local orderB = b.launcher and b.launcher.order or 999
      if orderA == orderB then
        return (a.name or a.id) < (b.name or b.id)
      end
      return orderA < orderB
    end)

    return items
  end

  return service
end

return appsService
