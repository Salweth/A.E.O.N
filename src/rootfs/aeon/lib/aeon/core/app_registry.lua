local filesystem = require("filesystem")

local appRegistry = {}

local function sortedKeys(map)
  local keys = {}
  for key in pairs(map) do
    table.insert(keys, key)
  end
  table.sort(keys)
  return keys
end

local function loadLuaFile(path)
  local chunk, err = loadfile(path)
  if not chunk then
    return nil, err
  end

  local ok, result = pcall(chunk)
  if not ok then
    return nil, result
  end

  return result
end

function appRegistry.create(root)
  local registry = {
    root = root or "/aeon/apps",
    apps = {}
  }

  function registry:scan()
    self.apps = {}
    if not filesystem.exists(self.root) then
      return self.apps
    end

    for entry in filesystem.list(self.root) do
      local appRoot = filesystem.concat(self.root, entry)
      local manifestPath = filesystem.concat(appRoot, "manifest.lua")

      if filesystem.isDirectory(appRoot) and filesystem.exists(manifestPath) then
        local manifest, err = loadLuaFile(manifestPath)
        if type(manifest) == "table" and manifest.id and manifest.entry then
          manifest.root = appRoot
          self.apps[manifest.id] = manifest
        else
          self.apps[entry] = {
            id = entry,
            name = entry,
            invalid = true,
            error = err or "Invalid manifest."
          }
        end
      end
    end

    return self.apps
  end

  function registry:listLaunchable()
    local items = {}
    for _, id in ipairs(sortedKeys(self.apps)) do
      local app = self.apps[id]
      if not app.invalid then
        table.insert(items, app)
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

  function registry:load(appId)
    local manifest = self.apps[appId]
    if not manifest or manifest.invalid then
      return nil, "Application unavailable: " .. tostring(appId)
    end

    local entry = loadLuaFile(manifest.entry)
    if not entry then
      return nil, "Unable to load app entry: " .. tostring(appId)
    end

    return manifest, entry
  end

  return registry
end

return appRegistry
