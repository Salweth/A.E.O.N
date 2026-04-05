local okComponent, component = pcall(require, "component")
local okComputer, computer = pcall(require, "computer")
local okEvent, event = pcall(require, "event")
local okKeyboard, keyboard = pcall(require, "keyboard")
local okTerm, term = pcall(require, "term")

local terminal = {}

local gpu = nil
if okComponent and component and component.isAvailable and component.isAvailable("gpu") then
  gpu = component.gpu
end

local palette = {
  bg = 0x0B0F14,
  panel = 0x121922,
  panelAlt = 0x17212C,
  text = 0xE6EEF5,
  dim = 0x8EA0AF,
  accent = 0x74E0FF,
  accentAlt = 0xF2C572,
  ok = 0x8FD694,
  warn = 0xF2C572,
  error = 0xF27D72,
  line = 0x355064
}

local cursorY = 1
local lastTouch = {
  x = nil,
  y = nil,
  time = 0
}
local audio = nil

local function write(text)
  io.write(tostring(text or ""))
end

local function canDraw()
  return gpu ~= nil
end

local function now()
  if okComputer and computer and computer.uptime then
    return computer.uptime()
  end
  return os.clock()
end

local function resolution()
  if canDraw() then
    return gpu.getResolution()
  end
  return 80, 25
end

local function setColors(fg, bg)
  if canDraw() then
    if bg then
      gpu.setBackground(bg)
    end
    if fg then
      gpu.setForeground(fg)
    end
  end
end

local function resetColors()
  setColors(palette.text, palette.bg)
end

local function clip(text, width)
  local value = tostring(text or "")
  if #value <= width then
    return value
  end
  if width <= 3 then
    return value:sub(1, width)
  end
  return value:sub(1, width - 3) .. "..."
end

local function writeLineFallback(text)
  io.write(tostring(text or "") .. "\n")
end

local function drawText(x, y, text, fg, bg, width)
  local value = tostring(text or "")
  if width then
    value = clip(value, width)
  end

  if canDraw() then
    setColors(fg or palette.text, bg or palette.bg)
    gpu.set(x, y, value)
    resetColors()
  else
    writeLineFallback(value)
  end
end

local function fill(x, y, width, height, char, fg, bg)
  if canDraw() then
    setColors(fg or palette.text, bg or palette.bg)
    gpu.fill(x, y, width, height, char or " ")
    resetColors()
  end
end

local function drawHorizontal(x, y, width, char, fg, bg)
  drawText(x, y, string.rep(char or "-", math.max(0, width)), fg, bg)
end

local function drawBox(x, y, width, height, title, colors)
  colors = colors or {}
  local fg = colors.fg or palette.line
  local bg = colors.bg or palette.panel
  local titleColor = colors.title or palette.accent

  if not canDraw() then
    writeLineFallback(string.rep("=", math.max(10, width)))
    if title and title ~= "" then
      writeLineFallback(title)
      writeLineFallback(string.rep("-", math.max(10, width)))
    end
    return
  end

  fill(x, y, width, height, " ", palette.text, bg)
  setColors(fg, bg)
  gpu.set(x, y, "+" .. string.rep("-", width - 2) .. "+")
  for row = y + 1, y + height - 2 do
    gpu.set(x, row, "|")
    gpu.set(x + width - 1, row, "|")
  end
  gpu.set(x, y + height - 1, "+" .. string.rep("-", width - 2) .. "+")

  if title and title ~= "" and width > 6 then
    local label = " " .. clip(title, width - 6) .. " "
    setColors(titleColor, bg)
    gpu.set(x + 2, y, label)
  end

  resetColors()
end

local function setCursorBelow(y)
  cursorY = y
  if okTerm and term and not canDraw() then
    term.setCursor(1, cursorY)
  end
end

function terminal.clear()
  local width, height = resolution()
  cursorY = 1

  if canDraw() then
    setColors(palette.text, palette.bg)
    gpu.fill(1, 1, width, height, " ")
  end

  if okTerm and term then
    term.clear()
    term.setCursor(1, 1)
  end

  resetColors()
end

function terminal.setAudio(service)
  audio = service
end

local function playCue(name)
  if not audio then
    return
  end

  local fn = audio[name]
  if type(fn) == "function" then
    pcall(fn, audio)
  end
end

function terminal.header(title, subtitle)
  local width = resolution()
  terminal.clear()

  if canDraw() then
    drawBox(2, 1, width - 2, 6, "AEON // OPERATIVE WORKSTATION", {
      fg = palette.line,
      bg = palette.panel,
      title = palette.accent
    })
    drawText(4, 3, clip(title or "Main", width - 8), palette.text, palette.panel)
    if subtitle and subtitle ~= "" then
      drawText(4, 4, clip(subtitle, width - 8), palette.dim, palette.panel)
    end
    setCursorBelow(8)
    return
  end

  writeLineFallback("========================================")
  writeLineFallback("AEON OPERATIVE WORKSTATION")
  writeLineFallback("========================================")
  writeLineFallback(title or "Main")
  if subtitle and subtitle ~= "" then
    writeLineFallback(subtitle)
  end
  writeLineFallback("----------------------------------------")
  setCursorBelow(7)
end

function terminal.section(title)
  if canDraw() then
    drawText(4, cursorY, "[ " .. tostring(title or "Section") .. " ]", palette.accentAlt, palette.bg)
  else
    writeLineFallback("[ " .. tostring(title or "Section") .. " ]")
  end
  cursorY = cursorY + 2
end

function terminal.info(text)
  if canDraw() then
    drawText(4, cursorY, "[INFO]", palette.accent, palette.bg)
    drawText(12, cursorY, tostring(text or ""), palette.text, palette.bg, resolution() - 14)
  else
    writeLineFallback("[INFO] " .. tostring(text or ""))
  end
  cursorY = cursorY + 1
end

function terminal.warn(text)
  if canDraw() then
    drawText(4, cursorY, "[WARN]", palette.warn, palette.bg)
    drawText(12, cursorY, tostring(text or ""), palette.text, palette.bg, resolution() - 14)
  else
    writeLineFallback("[WARN] " .. tostring(text or ""))
  end
  cursorY = cursorY + 1
end

function terminal.error(text)
  if canDraw() then
    drawText(4, cursorY, "[ERR ]", palette.error, palette.bg)
    drawText(12, cursorY, tostring(text or ""), palette.text, palette.bg, resolution() - 14)
  else
    writeLineFallback("[ERR ] " .. tostring(text or ""))
  end
  cursorY = cursorY + 1
end

function terminal.ok(text)
  if canDraw() then
    drawText(4, cursorY, "[ OK ]", palette.ok, palette.bg)
    drawText(12, cursorY, tostring(text or ""), palette.text, palette.bg, resolution() - 14)
  else
    writeLineFallback("[ OK ] " .. tostring(text or ""))
  end
  cursorY = cursorY + 1
end

function terminal.kv(label, value)
  if canDraw() then
    drawText(4, cursorY, clip((label or "Item") .. ":", 22), palette.dim, palette.bg)
    drawText(27, cursorY, tostring(value or ""), palette.text, palette.bg, resolution() - 29)
  else
    writeLineFallback(tostring(label or "Item") .. ": " .. tostring(value or ""))
  end
  cursorY = cursorY + 1
end

function terminal.spacer()
  cursorY = cursorY + 1
  if not canDraw() then
    writeLineFallback("")
  end
end

local function renderButtons(items)
  local width, height = resolution()
  local panelX = 3
  local panelY = cursorY
  local panelWidth = math.min(width - 4, 56)
  local buttonHeight = 3
  local panelHeight = math.max(6, (#items * buttonHeight) + 4)
  local buttons = {}

  drawBox(panelX, panelY, panelWidth, panelHeight, "Available Actions", {
    fg = palette.line,
    bg = palette.panelAlt,
    title = palette.accentAlt
  })

  for index, item in ipairs(items) do
    local buttonY = panelY + 1 + ((index - 1) * buttonHeight)
    local active = item.active ~= false
    local bg = active and palette.panel or palette.bg
    local fg = active and palette.text or palette.dim
    local accent = active and palette.accent or palette.dim
    fill(panelX + 2, buttonY, panelWidth - 4, 2, " ", fg, bg)
    drawText(panelX + 4, buttonY, tostring(index) .. ".", accent, bg)
    drawText(panelX + 8, buttonY, clip(item.label, panelWidth - 12), fg, bg)
    drawHorizontal(panelX + 2, buttonY + 1, panelWidth - 4, "-", palette.line, bg)

    table.insert(buttons, {
      index = index,
      x1 = panelX + 2,
      y1 = buttonY,
      x2 = panelX + panelWidth - 3,
      y2 = buttonY + 1,
      active = active
    })
  end

  drawText(panelX + 2, panelY + panelHeight - 2, "Touch a panel or use number keys.", palette.dim, palette.panelAlt, panelWidth - 4)
  cursorY = panelY + panelHeight + 1
  return buttons
end

local function selectionFromTouch(x, y, buttons)
  for _, button in ipairs(buttons or {}) do
    if button.active and x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
      return button.index
    end
  end
  return nil
end

local function isDebouncedTouch(x, y)
  local current = now()
  local sameSpot = lastTouch.x == x and lastTouch.y == y
  local tooSoon = (current - (lastTouch.time or 0)) < 0.35
  lastTouch.x = x
  lastTouch.y = y
  lastTouch.time = current
  return sameSpot and tooSoon
end

local function selectionFromKey(char, code, itemCount)
  if char and char >= 49 and char <= 57 then
    local index = char - 48
    if index >= 1 and index <= itemCount then
      return index
    end
  end

  if okKeyboard and keyboard and code == keyboard.keys.enter then
    return nil
  end

  return false
end

local function navigationFromKey(code, itemCount, selectedIndex)
  if not okKeyboard or not keyboard then
    return selectedIndex, false
  end

  if code == keyboard.keys.up then
    if selectedIndex <= 1 then
      return itemCount, false
    end
    return selectedIndex - 1, false
  end

  if code == keyboard.keys.down then
    if selectedIndex >= itemCount then
      return 1, false
    end
    return selectedIndex + 1, false
  end

  if code == keyboard.keys.enter then
    return selectedIndex, true
  end

  return selectedIndex, false
end

function terminal.menu(items)
  if not canDraw() or not okEvent or not event then
    terminal.section("Available Actions")
    for index, item in ipairs(items) do
      writeLineFallback(string.format("%d. %s", index, item.label))
    end
    writeLineFallback("")
    writeLineFallback("Enter a selection number and press return.")
    write("Selection > ")
    return tonumber(io.read() or "")
  end

  local buttons = renderButtons(items)

  while true do
    local signal = {event.pull()}
    local name = signal[1]

    if name == "touch" then
      local x = signal[3]
      local y = signal[4]
      if not isDebouncedTouch(x, y) then
        local choice = selectionFromTouch(x, y, buttons)
        if choice then
          playCue("click")
          return choice
        end
      end
    elseif name == "key_down" then
      local char = signal[3]
      local code = signal[4]
      local choice = selectionFromKey(char, code, #items)
      if choice ~= false then
        if choice ~= nil then
          playCue("confirm")
        end
        return choice
      end
    end
  end
end

function terminal.dashboard(session, devices, menuItems)
  if not canDraw() or not okEvent or not event then
    terminal.header("Agent Workstation", string.format("Agent: %s | Workstation: %s", session.agentName, session.workstationId))
    terminal.section("Operational Status")
    terminal.kv("Role", tostring(session.workstationRole))
    terminal.kv("Clearance", tostring(session.agentClearance))
    terminal.kv("Installed apps", tostring(#menuItems - 3))
    terminal.kv("Glasses", tostring(devices:isAvailable("glasses")))
    terminal.kv("Printer", tostring(devices:isAvailable("printer")))
    terminal.kv("Scanner", tostring(devices:isAvailable("scanner")))
    terminal.spacer()
    terminal.section("Main Menu")
    return terminal.menu(menuItems)
  end

  local width, height = resolution()
  local leftX = 3
  local leftY = 8
  local leftW = math.floor((width - 6) * 0.58)
  local rightX = leftX + leftW + 2
  local rightW = width - rightX - 1
  local menuPanelH = math.max(14, (#menuItems * 3) + 4)
  local statusH = 12
  local deviceH = 9

  local selectedIndex = 1
  local statusMessage = "Select a module with arrows, number keys, or touch."

  local function renderDashboard(armedIndex)
    terminal.clear()

    drawBox(2, 1, width - 2, 6, "AEON // OPERATIVE WORKSTATION", {
      fg = palette.line,
      bg = palette.panel,
      title = palette.accent
    })
    drawText(4, 3, "ACTIVE AGENT TERMINAL", palette.text, palette.panel, width - 8)
    drawText(4, 4, string.format("Agent %s // Workstation %s", session.agentName, session.workstationId), palette.dim, palette.panel, width - 8)

    drawBox(leftX, leftY, leftW, menuPanelH, "Mission Deck", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })

    local buttons = {}
    for index, item in ipairs(menuItems) do
      local buttonY = leftY + 1 + ((index - 1) * 3)
      local isSelected = index == selectedIndex
      local isArmed = armedIndex == index
      local bg = isSelected and palette.accent or palette.panel
      local fg = isSelected and palette.bg or palette.text
      local accent = isSelected and palette.bg or palette.accent
      local lineColor = isSelected and palette.accentAlt or palette.line

      if isArmed then
        bg = palette.accentAlt
        fg = palette.bg
        accent = palette.bg
        lineColor = palette.accent
      end

      fill(leftX + 2, buttonY, leftW - 4, 2, " ", fg, bg)
      drawText(leftX + 4, buttonY, string.format("%d.", index), accent, bg)
      drawText(leftX + 9, buttonY, clip(item.label, leftW - 13), fg, bg)
      drawHorizontal(leftX + 2, buttonY + 1, leftW - 4, "-", lineColor, bg)
      table.insert(buttons, {
        index = index,
        x1 = leftX + 2,
        y1 = buttonY,
        x2 = leftX + leftW - 3,
        y2 = buttonY + 1,
        active = true
      })
    end

    drawText(leftX + 2, leftY + menuPanelH - 2, statusMessage, palette.dim, palette.panelAlt, leftW - 4)

    drawBox(rightX, leftY, rightW, statusH, "Operational Status", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })
    drawText(rightX + 3, leftY + 2, "Role", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + 2, tostring(session.workstationRole), palette.text, palette.panelAlt, rightW - 18)
    drawText(rightX + 3, leftY + 4, "Clearance", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + 4, tostring(session.agentClearance), palette.text, palette.panelAlt, rightW - 18)
    drawText(rightX + 3, leftY + 6, "Loaded Apps", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + 6, tostring(#menuItems - 3), palette.text, palette.panelAlt, rightW - 18)
    drawText(rightX + 3, leftY + 8, "Focus", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + 8, clip(menuItems[selectedIndex].label, rightW - 18), palette.ok, palette.panelAlt, rightW - 18)

    drawBox(rightX, leftY + statusH + 1, rightW, deviceH, "Attached Devices", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })
    drawText(rightX + 3, leftY + statusH + 3, "Glasses", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + statusH + 3, tostring(devices:isAvailable("glasses")), devices:isAvailable("glasses") and palette.ok or palette.warn, palette.panelAlt)
    drawText(rightX + 3, leftY + statusH + 5, "Printer", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + statusH + 5, tostring(devices:isAvailable("printer")), devices:isAvailable("printer") and palette.ok or palette.warn, palette.panelAlt)
    drawText(rightX + 3, leftY + statusH + 7, "Scanner", palette.dim, palette.panelAlt)
    drawText(rightX + 15, leftY + statusH + 7, tostring(devices:isAvailable("scanner")), devices:isAvailable("scanner") and palette.ok or palette.warn, palette.panelAlt)

    drawText(3, height - 2, "Navigation: arrows, numbers, enter, or touch.", palette.dim, palette.bg, width - 6)
    drawText(3, height - 1, "AEON desk interface // Touch-enabled command deck", palette.dim, palette.bg, width - 6)

    return buttons
  end

  local buttons = renderDashboard()

  while true do
    local signal = {event.pull()}
    local name = signal[1]

    if name == "touch" then
      local x = signal[3]
      local y = signal[4]
      if not isDebouncedTouch(x, y) then
        local choice = selectionFromTouch(x, y, buttons)
        if choice then
          statusMessage = "Arming " .. tostring(menuItems[choice].label) .. "."
          playCue("click")
          buttons = renderDashboard(choice)
          return choice
        end
      end
    elseif name == "key_down" then
      local char = signal[3]
      local code = signal[4]
      local choice = selectionFromKey(char, code, #menuItems)
      if choice ~= false and choice ~= nil then
        statusMessage = "Arming " .. tostring(menuItems[choice].label) .. "."
        playCue("confirm")
        buttons = renderDashboard(choice)
        return choice
      end

      local newIndex, confirmed = navigationFromKey(code, #menuItems, selectedIndex)
      if newIndex ~= selectedIndex then
        selectedIndex = newIndex
        statusMessage = "Focused module: " .. tostring(menuItems[selectedIndex].label)
        playCue("focus")
        buttons = renderDashboard()
      elseif confirmed then
        statusMessage = "Arming " .. tostring(menuItems[selectedIndex].label) .. "."
        playCue("confirm")
        buttons = renderDashboard(selectedIndex)
        return selectedIndex
      end
    end
  end
end

function terminal.filesDashboard(state)
  local entries = state.entries or {}
  local selectedIndex = state.selectedIndex or 1

  if selectedIndex < 1 then
    selectedIndex = 1
  end
  if #entries == 0 then
    selectedIndex = 0
  elseif selectedIndex > #entries then
    selectedIndex = #entries
  end

  local actions = {
    {id = "open", label = "Open"},
    {id = "parent", label = "Parent"},
    {id = "mkdir", label = "New Folder"},
    {id = "newfile", label = "New File"},
    {id = "rename", label = "Rename"},
    {id = "copy", label = "Copy"},
    {id = "move", label = "Move"},
    {id = "delete", label = "Delete"},
    {id = "refresh", label = "Refresh"},
    {id = "exit", label = "Exit"}
  }

  if not canDraw() or not okEvent or not event then
    terminal.header("Files", state.subtitle or "Local workstation explorer")
    terminal.kv("Path", state.path or "/")
    terminal.kv("Root", state.root or "/aeon/data/files")
    terminal.spacer()
    for index, entry in ipairs(entries) do
      local marker = index == selectedIndex and ">" or " "
      local kind = entry.isDirectory and "DIR " or "FILE"
      terminal.info(string.format("%s %d. [%s] %s", marker, index, kind, entry.name))
    end
    terminal.spacer()
    local choice = terminal.menu({
      {label = "Open"},
      {label = "Parent"},
      {label = "New Folder"},
      {label = "New File"},
      {label = "Rename"},
      {label = "Copy"},
      {label = "Move"},
      {label = "Delete"},
      {label = "Refresh"},
      {label = "Exit"}
    })
    return selectedIndex, actions[choice] and actions[choice].id or nil
  end

  local width, height = resolution()
  local listX = 3
  local listY = 8
  local listW = math.floor((width - 6) * 0.58)
  local infoX = listX + listW + 2
  local infoW = width - infoX - 1
  local listH = math.max(14, height - 15)
  local infoH = math.max(10, math.floor((listH - 1) * 0.58))
  local actionY = listY + infoH + 1
  local actionH = listH - infoH - 1

  local function render(currentSelection, armedAction)
    terminal.clear()
    drawBox(2, 1, width - 2, 6, "AEON // FILES", {
      fg = palette.line,
      bg = palette.panel,
      title = palette.accent
    })
    drawText(4, 3, clip(state.subtitle or "Local workstation explorer", width - 8), palette.text, palette.panel)
    drawText(4, 4, clip("Path " .. tostring(state.path or "/"), width - 8), palette.dim, palette.panel)

    drawBox(listX, listY, listW, listH, "Directory Listing", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })

    drawText(listX + 2, listY + 1, "Current", palette.dim, palette.panelAlt)
    drawText(listX + 12, listY + 1, clip(state.path or "/", listW - 14), palette.text, palette.panelAlt)
    drawText(listX + 2, listY + 2, "Entries", palette.dim, palette.panelAlt)
    drawText(listX + 12, listY + 2, tostring(#entries), palette.text, palette.panelAlt)

    local visibleRows = math.max(4, listH - 5)
    local startIndex = 1
    if currentSelection > visibleRows then
      startIndex = currentSelection - visibleRows + 1
    end

    local listButtons = {}
    for row = 1, visibleRows do
      local index = startIndex + row - 1
      if index > #entries then
        break
      end
      local entry = entries[index]
      local rowY = listY + 2 + row
      local selected = index == currentSelection
      local bg = selected and palette.accent or palette.panel
      local fg = selected and palette.bg or palette.text
      local kindColor = selected and palette.bg or (entry.isDirectory and palette.accentAlt or palette.accent)

      fill(listX + 2, rowY, listW - 4, 1, " ", fg, bg)
      drawText(listX + 3, rowY, string.format("%02d", index), kindColor, bg)
      drawText(listX + 7, rowY, entry.isDirectory and "[DIR]" or "[TXT]", kindColor, bg)
      drawText(listX + 13, rowY, clip(entry.name, listW - 16), fg, bg)

      table.insert(listButtons, {
        index = index,
        x1 = listX + 2,
        y1 = rowY,
        x2 = listX + listW - 3,
        y2 = rowY,
        active = true
      })
    end

    drawBox(infoX, listY, infoW, infoH, "Selection Details", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })

    local selected = entries[currentSelection]
    if selected then
      drawText(infoX + 2, listY + 2, "Name", palette.dim, palette.panelAlt)
      drawText(infoX + 12, listY + 2, clip(selected.name, infoW - 14), palette.text, palette.panelAlt)
      drawText(infoX + 2, listY + 4, "Type", palette.dim, palette.panelAlt)
      drawText(infoX + 12, listY + 4, selected.isDirectory and "Folder" or "Text file", palette.text, palette.panelAlt)
      drawText(infoX + 2, listY + 6, "Path", palette.dim, palette.panelAlt)
      drawText(infoX + 12, listY + 6, clip(selected.path, infoW - 14), palette.text, palette.panelAlt)
      drawText(infoX + 2, listY + 8, "Action", palette.dim, palette.panelAlt)
      drawText(infoX + 12, listY + 8, selected.isDirectory and "Open folder" or "Open or edit file", palette.ok, palette.panelAlt)
    else
      drawText(infoX + 2, listY + 2, "No selection available.", palette.warn, palette.panelAlt)
      drawText(infoX + 2, listY + 4, "Create a folder or a file to start.", palette.dim, palette.panelAlt, infoW - 4)
    end

    drawBox(infoX, actionY, infoW, actionH, "Command Deck", {
      fg = palette.line,
      bg = palette.panelAlt,
      title = palette.accentAlt
    })

    local actionButtons = {}
    local buttonWidth = math.floor((infoW - 6) / 2)
    for index, action in ipairs(actions) do
      local col = ((index - 1) % 2)
      local row = math.floor((index - 1) / 2)
      local buttonX = infoX + 2 + (col * buttonWidth)
      local buttonY = actionY + 1 + (row * 2)
      local armed = armedAction == action.id
      local bg = armed and palette.accentAlt or palette.panel
      local fg = armed and palette.bg or palette.text
      local accent = armed and palette.bg or palette.accent

      fill(buttonX, buttonY, buttonWidth - 1, 1, " ", fg, bg)
      drawText(buttonX + 1, buttonY, tostring(index) .. ".", accent, bg)
      drawText(buttonX + 5, buttonY, clip(action.label, buttonWidth - 7), fg, bg)

      table.insert(actionButtons, {
        id = action.id,
        index = index,
        x1 = buttonX,
        y1 = buttonY,
        x2 = buttonX + buttonWidth - 2,
        y2 = buttonY,
        active = true
      })
    end

    drawText(3, height - 1, "Files // arrows to move, enter to open, numbers for actions, touch to select.", palette.dim, palette.bg, width - 6)
    return listButtons, actionButtons
  end

  local listButtons, actionButtons = render(selectedIndex)

  while true do
    local signal = {event.pull()}
    local name = signal[1]

    if name == "touch" then
      local x = signal[3]
      local y = signal[4]
      if not isDebouncedTouch(x, y) then
        local touchedEntry = selectionFromTouch(x, y, listButtons)
        if touchedEntry then
          if touchedEntry == selectedIndex then
            playCue("click")
            return selectedIndex, "open"
          end
          selectedIndex = touchedEntry
          playCue("focus")
          listButtons, actionButtons = render(selectedIndex)
        else
          for _, button in ipairs(actionButtons) do
            if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
              playCue("confirm")
              listButtons, actionButtons = render(selectedIndex, button.id)
              return selectedIndex, button.id
            end
          end
        end
      end
    elseif name == "key_down" then
      local char = signal[3]
      local code = signal[4]

      local actionIndex = nil
      if char and char >= 49 and char <= 57 then
        actionIndex = char - 48
      elseif char == 48 then
        actionIndex = 10
      end

      if actionIndex then
        local action = actions[actionIndex]
        if action then
          playCue("confirm")
          listButtons, actionButtons = render(selectedIndex, action.id)
          return selectedIndex, action.id
        end
      end

      if okKeyboard and keyboard then
        if code == keyboard.keys.up and #entries > 0 then
          selectedIndex = selectedIndex <= 1 and #entries or (selectedIndex - 1)
          playCue("focus")
          listButtons, actionButtons = render(selectedIndex)
        elseif code == keyboard.keys.down and #entries > 0 then
          selectedIndex = selectedIndex >= #entries and 1 or (selectedIndex + 1)
          playCue("focus")
          listButtons, actionButtons = render(selectedIndex)
        elseif code == keyboard.keys.enter then
          playCue("confirm")
          listButtons, actionButtons = render(selectedIndex, "open")
          return selectedIndex, "open"
        elseif code == keyboard.keys.back then
          playCue("confirm")
          listButtons, actionButtons = render(selectedIndex, "parent")
          return selectedIndex, "parent"
        end
      end
    end
  end
end

function terminal.prompt(label)
  if canDraw() then
    drawText(4, cursorY, tostring(label or "Input") .. " >", palette.dim, palette.bg)
  else
    write(tostring(label or "Input") .. " > ")
  end
  if okTerm and term and canDraw() then
    term.setCursor(#tostring(label or "Input") + 7, cursorY)
  end
  local value = io.read()
  cursorY = cursorY + 1
  return value
end

function terminal.pause(label)
  if canDraw() then
    local width, height = resolution()
    local text = tostring(label or "Press enter, click, or tap to continue.")
    drawText(4, height - 1, clip(text, width - 8), palette.dim, palette.bg)
  else
    write((label or "Press enter to continue.") .. " ")
  end

  if okEvent and event then
    while true do
      local signal = {event.pull()}
      local name = signal[1]
      if name == "touch" then
        break
      end
      if name == "key_down" then
        if not okKeyboard or not keyboard or signal[4] == keyboard.keys.enter then
          break
        end
      end
    end
  else
    io.read()
  end
end

return terminal
