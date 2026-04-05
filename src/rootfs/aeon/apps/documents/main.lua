local function displayPath(path)
  if not path or path == "" then
    return "/"
  end
  return path
end

local function chooseEntry(ui, entries)
  if #entries == 0 then
    ui.warn("This folder is empty.")
    ui.pause()
    return nil
  end

  local raw = ui.prompt("Select entry number")
  local index = tonumber(raw or "")
  if not index or not entries[index] then
    ui.warn("Invalid entry selection.")
    ui.pause()
    return nil
  end
  return entries[index]
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
  local existing = fs:readText(relativePath)
  ui.header("Files", "Editing " .. displayPath(relativePath))
  if existing and existing ~= "" then
    ui.section("Current Content")
    for line in (existing .. "\n"):gmatch("(.-)\n") do
      ui.info(line)
    end
    ui.spacer()
  end

  local content = readMultiline(ui)
  local ok, err = fs:updateText(relativePath, content)
  if not ok then
    ui.error(err or "Unable to save file.")
  else
    ui.ok("File updated.")
  end
  ui.pause()
end

return {
  run = function(context)
    local ui = context.ui
    local fs = context.services.filesystem
    local currentPath = "/"

    while true do
      local entries, err = fs:list(currentPath)
      if not entries then
        ui.header("Files", "Local workstation explorer")
        ui.error(err or "Unable to list folder.")
        ui.pause()
        return
      end

      ui.header("Files", "Local workstation explorer")
      ui.section("Current Folder")
      ui.kv("Path", displayPath(currentPath))
      ui.kv("Root", fs:rootPath())

      ui.spacer()
      ui.section("Folder Contents")
      if #entries == 0 then
        ui.warn("No files or folders in this location.")
      else
        for index, entry in ipairs(entries) do
          local kind = entry.isDirectory and "DIR " or "FILE"
          ui.info(string.format("%d. [%s] %s", index, kind, entry.name))
        end
      end

      ui.spacer()
      local choice = ui.menu({
        {label = "Open entry"},
        {label = "Go to parent folder"},
        {label = "Create folder"},
        {label = "Create text file"},
        {label = "Rename entry"},
        {label = "Delete entry"},
        {label = "Refresh"},
        {label = "Exit"}
      })

      if choice == 1 then
        local selected = chooseEntry(ui, entries)
        if selected then
          if selected.isDirectory then
            currentPath = selected.path
          else
            local action = ui.menu({
              {label = "View file"},
              {label = "Edit file"},
              {label = "Cancel"}
            })
            if action == 1 then
              showFile(ui, fs, selected.path)
            elseif action == 2 then
              editFile(ui, fs, selected.path)
            end
          end
        end
      elseif choice == 2 then
        currentPath = fs:parent(currentPath)
      elseif choice == 3 then
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
      elseif choice == 4 then
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
      elseif choice == 5 then
        local selected = chooseEntry(ui, entries)
        if selected then
          local newName = ui.prompt("New name")
          if newName and newName ~= "" then
            local ok, renameErr = fs:rename(selected.path, newName)
            if not ok then
              ui.error(renameErr or "Unable to rename entry.")
            else
              ui.ok("Entry renamed.")
            end
            ui.pause()
          end
        end
      elseif choice == 6 then
        local selected = chooseEntry(ui, entries)
        if selected then
          local confirm = ui.prompt("Type DELETE to confirm")
          if confirm == "DELETE" then
            local ok, deleteErr = fs:delete(selected.path)
            if not ok then
              ui.error(deleteErr or "Unable to delete entry.")
            else
              ui.ok("Entry deleted.")
            end
            ui.pause()
          end
        end
      elseif choice == 7 then
        -- Refresh loop iteration
      elseif choice == 8 then
        return
      else
        ui.warn("Invalid selection.")
        ui.pause()
      end
    end
  end
}
