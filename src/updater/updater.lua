local filesystem = require("filesystem")
local shell = require("shell")

local args, options = shell.parse(...)
local repo = options.repo or "Salweth/A.E.O.N"
local branch = options.branch or "main"
local manifestUrl = options.manifest or ("https://raw.githubusercontent.com/" .. repo .. "/" .. branch .. "/src/updater/release_manifest.lua")
local tempManifestPath = "/tmp/aeon-release-manifest.lua"

local function info(message)
  io.write("[AEON updater] " .. tostring(message or "") .. "\n")
end

local function fail(message)
  io.stderr:write("[AEON updater] " .. tostring(message or "Unknown error.") .. "\n")
  return nil, message
end

local function ensureDir(path)
  if not filesystem.exists(path) then
    filesystem.makeDirectory(path)
  end
end

local function run(command, ...)
  local ok, reason = shell.execute(command, ...)
  if ok == false then
    return nil, reason
  end
  return true
end

local function download(url, target)
  local parent = filesystem.path(target)
  if parent and parent ~= "" then
    ensureDir(parent)
  end

  if filesystem.exists(target) then
    filesystem.remove(target)
  end

  local ok, err = run("wget", "-fq", url, target)
  if not ok or not filesystem.exists(target) then
    return nil, err or ("Download failed for " .. url)
  end

  return true
end

local function loadManifest(path)
  local chunk, err = loadfile(path)
  if not chunk then
    return nil, err
  end

  local ok, result = pcall(chunk)
  if not ok then
    return nil, result
  end

  if type(result) ~= "table" then
    return nil, "Manifest must return a table."
  end

  return result
end

local function saveVersion(version)
  ensureDir("/aeon/config")
  local handle, err = io.open("/aeon/config/version.txt", "w")
  if not handle then
    return nil, err
  end

  handle:write(tostring(version or "unknown"))
  handle:close()
  return true
end

local function removeFileIfExists(path)
  if filesystem.exists(path) and not filesystem.isDirectory(path) then
    filesystem.remove(path)
  end
end

local function installFromManifest(manifest)
  local releaseRepo = manifest.repo or repo
  local releaseBranch = manifest.branch or branch
  local baseUrl = "https://raw.githubusercontent.com/" .. releaseRepo .. "/" .. releaseBranch .. "/"

  info("Preparing directories")
  for _, path in ipairs(manifest.directories or {}) do
    ensureDir(path)
  end

  info("Downloading release files")
  for index, file in ipairs(manifest.files or {}) do
    local url = baseUrl .. file.source
    info(string.format("[%d/%d] %s", index, #manifest.files, file.target))
    removeFileIfExists(file.target)
    local ok, err = download(url, file.target)
    if not ok then
      return nil, err
    end
  end

  if manifest.version then
    local ok, err = saveVersion(manifest.version)
    if not ok then
      return nil, err
    end
  end

  return true
end

local function main()
  info("Fetching release manifest")
  ensureDir("/tmp")
  local ok, err = download(manifestUrl, tempManifestPath)
  if not ok then
    return fail(err)
  end

  local manifest, manifestErr = loadManifest(tempManifestPath)
  if not manifest then
    return fail(manifestErr)
  end

  info("Release version: " .. tostring(manifest.version or "unknown"))
  local installed, installErr = installFromManifest(manifest)
  if not installed then
    return fail(installErr)
  end

  info("Update complete.")
  info("Launch with: aeon")
  return true
end

return main()
