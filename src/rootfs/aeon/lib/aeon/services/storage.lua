local filesystem = require("filesystem")

local storageService = {}

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

function storageService.create(root)
  local service = {
    root = root or "/aeon/data"
  }

  function service:init()
    ensureDir(self.root)
    ensureDir(filesystem.concat(self.root, "missions"))
    ensureDir(filesystem.concat(self.root, "files"))
    ensureDir(filesystem.concat(self.root, "downloads"))
    ensureDir(filesystem.concat(self.root, "notes"))
    ensureDir(filesystem.concat(self.root, "tmp"))
    return true
  end

  function service:path(...)
    local parts = {...}
    local path = self.root
    for _, part in ipairs(parts) do
      path = filesystem.concat(path, part)
    end
    return path
  end

  return service
end

return storageService
