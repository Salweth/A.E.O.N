local filesystem = require("filesystem")

local filesystemService = {}

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function trimSlashes(value)
  local text = tostring(value or "")
  text = text:gsub("\\", "/")
  text = text:gsub("^/+", "")
  text = text:gsub("/+$", "")
  return text
end

local function readFile(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil, "Unable to open file."
  end

  local content = handle:read("*a")
  handle:close()
  return content or ""
end

local function writeFile(path, content)
  local handle, err = io.open(path, "w")
  if not handle then
    return nil, err or "Unable to write file."
  end

  handle:write(content or "")
  handle:close()
  return true
end

local function basename(path)
  local value = tostring(path or ""):gsub("\\", "/"):gsub("/+$", "")
  return value:match("([^/]+)$") or value
end

local function copyRecursive(source, target)
  if filesystem.isDirectory(source) then
    if not filesystem.exists(target) then
      filesystem.makeDirectory(target)
    end

    for name in filesystem.list(source) do
      local cleanName = tostring(name or ""):gsub("/$", "")
      local childSource = filesystem.concat(source, cleanName)
      local childTarget = filesystem.concat(target, cleanName)
      local ok, err = copyRecursive(childSource, childTarget)
      if not ok then
        return nil, err
      end
    end

    return true
  end

  local content, err = readFile(source)
  if content == nil then
    return nil, err
  end
  return writeFile(target, content)
end

function filesystemService.create(root)
  local service = {
    root = root or "/aeon/data/files"
  }

  function service:init()
    ensureDir("/aeon/data")
    ensureDir(self.root)
    ensureDir(filesystem.concat(self.root, "downloads"))
    ensureDir(filesystem.concat(self.root, "notes"))
    ensureDir(filesystem.concat(self.root, "tmp"))
    return true
  end

  function service:rootPath()
    return self.root
  end

  function service:resolve(relativePath)
    local clean = trimSlashes(relativePath or "")
    if clean == "" then
      return self.root
    end

    local parts = {}
    for part in clean:gmatch("[^/]+") do
      if part == ".." then
        return nil, "Parent traversal is not allowed."
      elseif part ~= "." and part ~= "" then
        table.insert(parts, part)
      end
    end

    local path = self.root
    for _, part in ipairs(parts) do
      path = filesystem.concat(path, part)
    end
    return path
  end

  function service:relative(absolutePath)
    local path = tostring(absolutePath or ""):gsub("\\", "/")
    local root = tostring(self.root):gsub("\\", "/")
    if path == root then
      return "/"
    end
    if path:sub(1, #root) == root then
      local suffix = path:sub(#root + 1)
      if suffix == "" then
        return "/"
      end
      return suffix
    end
    return path
  end

  function service:list(relativePath)
    self:init()
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    if not filesystem.exists(path) then
      return nil, "Folder does not exist."
    end
    if not filesystem.isDirectory(path) then
      return nil, "Target is not a directory."
    end

    local items = {}
    for name in filesystem.list(path) do
      local cleanName = tostring(name or ""):gsub("/$", "")
      local fullPath = filesystem.concat(path, cleanName)
      table.insert(items, {
        name = cleanName,
        path = self:relative(fullPath),
        isDirectory = filesystem.isDirectory(fullPath)
      })
    end

    table.sort(items, function(a, b)
      if a.isDirectory ~= b.isDirectory then
        return a.isDirectory
      end
      return a.name:lower() < b.name:lower()
    end)

    return items
  end

  function service:makeDirectory(currentRelativePath, name)
    self:init()
    local parent, err = self:resolve(currentRelativePath)
    if not parent then
      return nil, err
    end

    local folderName = trimSlashes(name)
    if folderName == "" then
      return nil, "Folder name is required."
    end
    if folderName:find("/") then
      return nil, "Nested paths are not allowed here."
    end

    local target = filesystem.concat(parent, folderName)
    if filesystem.exists(target) then
      return nil, "An entry with this name already exists."
    end

    filesystem.makeDirectory(target)
    return true
  end

  function service:createTextFile(currentRelativePath, name, content)
    self:init()
    local parent, err = self:resolve(currentRelativePath)
    if not parent then
      return nil, err
    end

    local fileName = trimSlashes(name)
    if fileName == "" then
      return nil, "File name is required."
    end
    if fileName:find("/") then
      return nil, "Nested paths are not allowed here."
    end

    local target = filesystem.concat(parent, fileName)
    if filesystem.exists(target) then
      return nil, "An entry with this name already exists."
    end

    return writeFile(target, content or "")
  end

  function service:readText(relativePath)
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    if not filesystem.exists(path) then
      return nil, "File does not exist."
    end
    if filesystem.isDirectory(path) then
      return nil, "Cannot read a directory."
    end
    return readFile(path)
  end

  function service:exists(relativePath)
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    return filesystem.exists(path)
  end

  function service:updateText(relativePath, content)
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    if filesystem.isDirectory(path) then
      return nil, "Cannot write a directory."
    end
    return writeFile(path, content or "")
  end

  function service:delete(relativePath)
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    if path == self.root then
      return nil, "Cannot delete the root files directory."
    end
    if not filesystem.exists(path) then
      return nil, "Entry does not exist."
    end

    filesystem.remove(path)
    return true
  end

  function service:rename(relativePath, newName)
    local path, err = self:resolve(relativePath)
    if not path then
      return nil, err
    end
    if path == self.root then
      return nil, "Cannot rename the root files directory."
    end

    local parent = filesystem.path(path)
    local cleanName = trimSlashes(newName)
    if cleanName == "" then
      return nil, "New name is required."
    end
    if cleanName:find("/") then
      return nil, "Nested paths are not allowed here."
    end

    local target = filesystem.concat(parent, cleanName)
    if filesystem.exists(target) then
      return nil, "An entry with this name already exists."
    end

    local ok = filesystem.rename(path, target)
    if not ok then
      return nil, "Rename failed."
    end
    return true
  end

  function service:copy(relativePath, destinationFolderRelativePath, newName)
    local source, sourceErr = self:resolve(relativePath)
    if not source then
      return nil, sourceErr
    end
    if not filesystem.exists(source) then
      return nil, "Source entry does not exist."
    end

    local destinationFolder, destErr = self:resolve(destinationFolderRelativePath)
    if not destinationFolder then
      return nil, destErr
    end
    if not filesystem.exists(destinationFolder) or not filesystem.isDirectory(destinationFolder) then
      return nil, "Destination folder does not exist."
    end

    local finalName = trimSlashes(newName or basename(source))
    if finalName == "" then
      return nil, "Destination name is required."
    end
    if finalName:find("/") then
      return nil, "Nested destination names are not allowed."
    end

    local target = filesystem.concat(destinationFolder, finalName)
    if filesystem.exists(target) then
      return nil, "Destination entry already exists."
    end

    return copyRecursive(source, target)
  end

  function service:move(relativePath, destinationFolderRelativePath, newName)
    local source, sourceErr = self:resolve(relativePath)
    if not source then
      return nil, sourceErr
    end
    if source == self.root then
      return nil, "Cannot move the root files directory."
    end
    if not filesystem.exists(source) then
      return nil, "Source entry does not exist."
    end

    local destinationFolder, destErr = self:resolve(destinationFolderRelativePath)
    if not destinationFolder then
      return nil, destErr
    end
    if not filesystem.exists(destinationFolder) or not filesystem.isDirectory(destinationFolder) then
      return nil, "Destination folder does not exist."
    end

    local finalName = trimSlashes(newName or basename(source))
    if finalName == "" then
      return nil, "Destination name is required."
    end
    if finalName:find("/") then
      return nil, "Nested destination names are not allowed."
    end

    local target = filesystem.concat(destinationFolder, finalName)
    if filesystem.exists(target) then
      return nil, "Destination entry already exists."
    end

    local ok = filesystem.rename(source, target)
    if ok then
      return true
    end

    local copied, copyErr = copyRecursive(source, target)
    if not copied then
      return nil, copyErr
    end

    filesystem.remove(source)
    return true
  end

  function service:parent(relativePath)
    local clean = trimSlashes(relativePath or "")
    if clean == "" then
      return "/"
    end

    local parts = {}
    for part in clean:gmatch("[^/]+") do
      table.insert(parts, part)
    end
    table.remove(parts)
    if #parts == 0 then
      return "/"
    end
    return "/" .. table.concat(parts, "/")
  end

  return service
end

return filesystemService
