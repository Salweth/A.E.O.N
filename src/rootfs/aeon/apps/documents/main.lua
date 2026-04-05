local function displayPath(path)
  if not path or path == "" then
    return "/"
  end
  return path
end

local function readMultiline(ui)
  ui.section("Text Input")
  ui.info("Enter text line by line.")
  ui.info("Submit a single dot '.' on its own line to finish.")

  local lines = {}
  while true do
    local value = ui.prompt("line")
    if value == "." then
      break
    end
    table.insert(lines, value or "")
  end
  return table.concat(lines, "\n")
end

local function appendText(original, extra)
  local base = tostring(original or "")
  local suffix = tostring(extra or "")
  if base == "" then
    return suffix
  end
  if suffix == "" then
    return base
  end
  return base .. "\n" .. suffix
end

local function buildPreview(fs, entry)
  if not entry or entry.isDirectory then
    return nil
  end

  local content = fs:readText(entry.path)
  if not content then
    return nil
  end
  return tostring(content or "")
end

local function showFile(ui, fs, relativePath)
  local content, err = fs:readText(relativePath)
  if not content then
    ui.error(err or "Unable to read file.")
    ui.pause()
    return
  end

  ui.header("Files", "Viewing " .. displayPath(relativePath))
  ui.section("Content")
  if content == "" then
    ui.warn("File is empty.")
  else
    for line in (content .. "\n"):gmatch("(.-)\n") do
      ui.info(line)
    end
  end
  ui.pause()
end

local function editFile(ui, fs, relativePath)
  local existing, readErr = fs:readText(relativePath)
  if existing == nil then
    ui.error(readErr or "Unable to load file.")
    ui.pause()
    return
  end

  while true do
    ui.header("Files", "Editing " .. displayPath(relativePath))
    ui.section("Current Content")
    if existing == "" then
      ui.warn("File is currently empty.")
    else
      for line in (existing .. "\n"):gmatch("(.-)\n") do
        ui.info(line)
      end
    end

    ui.spacer()
    local action = ui.menu({
      {label = "Replace content"},
      {label = "Append text"},
      {label = "Add quick line"},
      {label = "Clear file"},
      {label = "Return"}
    })

    if action == 1 then
      ui.header("Files", "Replace content")
      local content = readMultiline(ui)
      local ok, err = fs:updateText(relativePath, content)
      if not ok then
        ui.error(err or "Unable to save file.")
      else
        existing = content
        ui.ok("File replaced.")
      end
      ui.pause()
    elseif action == 2 then
      ui.header("Files", "Append text")
      local content = readMultiline(ui)
      local merged = appendText(existing, content)
      local ok, err = fs:updateText(relativePath, merged)
      if not ok then
        ui.error(err or "Unable to save file.")
      else
        existing = merged
        ui.ok("Text appended.")
      end
      ui.pause()
    elseif action == 3 then
      local line = ui.prompt("Line to append")
      if line and line ~= "" then
        local merged = appendText(existing, line)
        local ok, err = fs:updateText(relativePath, merged)
        if not ok then
          ui.error(err or "Unable to save file.")
        else
          existing = merged
          ui.ok("Line appended.")
        end
        ui.pause()
      end
    elseif action == 4 then
      local confirm = ui.prompt("Type CLEAR to confirm")
      if confirm == "CLEAR" then
        local ok, err = fs:updateText(relativePath, "")
        if not ok then
          ui.error(err or "Unable to clear file.")
        else
          existing = ""
          ui.ok("File cleared.")
        end
        ui.pause()
      end
    else
      return
    end
  end
end

return {
  run = function(context)
    local ui = context.ui
    local fs = context.services.filesystem
    local currentPath = "/"
    local selectedIndex = 1
    local previewOffset = 0

    while true do
      local entries, err = fs:list(currentPath)
      if not entries then
        ui.header("Files", "Local workstation explorer")
        ui.error(err or "Unable to list folder.")
        ui.pause()
        return
      end

      if #entries == 0 then
        selectedIndex = 0
      elseif selectedIndex < 1 then
        selectedIndex = 1
      elseif selectedIndex > #entries then
        selectedIndex = #entries
      end

      local selected, action, nextPreviewOffset = ui.filesDashboard({
        subtitle = "Local workstation explorer",
        path = displayPath(currentPath),
        root = fs:rootPath(),
        entries = entries,
        selectedIndex = selectedIndex,
        previewOffset = previewOffset,
        previewProvider = function(entry)
          return buildPreview(fs, entry)
        end
      })

      selectedIndex = selected or selectedIndex
      previewOffset = nextPreviewOffset or 0
      local selectedEntry = entries[selectedIndex]

      if action == "open" then
        if selectedEntry then
          if selectedEntry.isDirectory then
            currentPath = selectedEntry.path
            selectedIndex = 1
            previewOffset = 0
          else
            local action = ui.menu({
              {label = "View file"},
              {label = "Edit file"},
              {label = "Cancel"}
            })
            if action == 1 then
              showFile(ui, fs, selectedEntry.path)
            elseif action == 2 then
              editFile(ui, fs, selectedEntry.path)
            end
          end
        end
      elseif action == "parent" then
        currentPath = fs:parent(currentPath)
        selectedIndex = 1
        previewOffset = 0
      elseif action == "mkdir" then
        local name = ui.prompt("New folder name")
        if name and name ~= "" then
          local ok, createErr = fs:makeDirectory(currentPath, name)
          if not ok then
            ui.error(createErr or "Unable to create folder.")
          else
            ui.ok("Folder created.")
          end
          ui.pause()
        end
      elseif action == "newfile" then
        local name = ui.prompt("New file name")
        if name and name ~= "" then
          ui.header("Files", "Create text file")
          local content = readMultiline(ui)
          local ok, createErr = fs:createTextFile(currentPath, name, content)
          if not ok then
            ui.error(createErr or "Unable to create file.")
          else
            ui.ok("File created.")
          end
          ui.pause()
        end
      elseif action == "rename" then
        if selectedEntry then
          local newName = ui.prompt("New name")
          if newName and newName ~= "" then
            local ok, renameErr = fs:rename(selectedEntry.path, newName)
            if not ok then
              ui.error(renameErr or "Unable to rename entry.")
            else
              ui.ok("Entry renamed.")
            end
            ui.pause()
          end
        end
      elseif action == "copy" then
        if selectedEntry then
          local destination = ui.prompt("Destination folder path")
          if destination and destination ~= "" then
            local newName = ui.prompt("Copy name (leave blank to keep)")
            local ok, copyErr = fs:copy(selectedEntry.path, destination, newName ~= "" and newName or nil)
            if not ok then
              ui.error(copyErr or "Unable to copy entry.")
            else
              ui.ok("Entry copied.")
            end
            ui.pause()
          end
        end
      elseif action == "move" then
        if selectedEntry then
          local destination = ui.prompt("Destination folder path")
          if destination and destination ~= "" then
            local newName = ui.prompt("New name at destination (leave blank to keep)")
            local ok, moveErr = fs:move(selectedEntry.path, destination, newName ~= "" and newName or nil)
            if not ok then
              ui.error(moveErr or "Unable to move entry.")
            else
              ui.ok("Entry moved.")
              selectedIndex = 1
              previewOffset = 0
            end
            ui.pause()
          end
        end
      elseif action == "delete" then
        if selectedEntry then
          local confirm = ui.prompt("Type DELETE to confirm")
          if confirm == "DELETE" then
            local ok, deleteErr = fs:delete(selectedEntry.path)
            if not ok then
              ui.error(deleteErr or "Unable to delete entry.")
            else
              ui.ok("Entry deleted.")
            end
            ui.pause()
          end
        end
      elseif action == "refresh" then
        -- Refresh loop iteration
      elseif action == "exit" then
        return
      else
        ui.warn("Invalid selection.")
        ui.pause()
      end
    end
  end
}
