local okComponent, component = pcall(require, "component")
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

local function write(text)
  io.write(tostring(text or ""))
end

local function line(text)
  write((text or "") .. "\n")
end

local function repeatChar(char, count)
  if count <= 0 then
    return ""
  end
  return string.rep(char, count)
end

local function screenWidth()
  if gpu and gpu.getResolution then
    local width = select(1, gpu.getResolution())
    if width and width > 0 then
      return width
    end
  end
  return 50
end

local function setColors(fg, bg)
  if gpu then
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

local function safeText(text, maxWidth)
  local value = tostring(text or "")
  if #value <= maxWidth then
    return value
  end
  if maxWidth <= 3 then
    return value:sub(1, maxWidth)
  end
  return value:sub(1, maxWidth - 3) .. "..."
end

local function contentWidth()
  return math.max(30, screenWidth() - 6)
end

local function borderLine(char)
  return repeatChar(char, contentWidth())
end

function terminal.clear()
  if gpu then
    setColors(palette.text, palette.bg)
    local width, height = gpu.getResolution()
    gpu.fill(1, 1, width, height, " ")
  end
  if okTerm and term then
    term.clear()
    term.setCursor(1, 1)
  end
  resetColors()
end

function terminal.header(title, subtitle)
  local width = contentWidth()
  terminal.clear()
  setColors(palette.accent, palette.bg)
  line(borderLine("="))
  line(safeText("AEON OPERATIVE WORKSTATION", width))
  line(borderLine("="))
  line("")
  setColors(palette.text, palette.bg)
  line(safeText(title or "Main", width))
  if subtitle and subtitle ~= "" then
    setColors(palette.dim, palette.bg)
    line(safeText(subtitle, width))
  end
  setColors(palette.line, palette.bg)
  line(borderLine("-"))
  resetColors()
end

function terminal.section(title)
  setColors(palette.accentAlt, palette.bg)
  line(safeText("[ " .. tostring(title or "Section") .. " ]", contentWidth()))
  resetColors()
end

function terminal.info(text)
  setColors(palette.accent, palette.bg)
  write("[INFO] ")
  setColors(palette.text, palette.bg)
  line(safeText(text or "", contentWidth() - 7))
end

function terminal.warn(text)
  setColors(palette.warn, palette.bg)
  write("[WARN] ")
  setColors(palette.text, palette.bg)
  line(safeText(text or "", contentWidth() - 7))
end

function terminal.error(text)
  setColors(palette.error, palette.bg)
  write("[ERR ] ")
  setColors(palette.text, palette.bg)
  line(safeText(text or "", contentWidth() - 7))
end

function terminal.ok(text)
  setColors(palette.ok, palette.bg)
  write("[ OK ] ")
  setColors(palette.text, palette.bg)
  line(safeText(text or "", contentWidth() - 7))
end

function terminal.kv(label, value)
  local width = contentWidth()
  local key = safeText((label or "Item") .. ":", math.floor(width * 0.4))
  local val = safeText(value or "", width - #key - 1)
  setColors(palette.dim, palette.bg)
  write(key)
  setColors(palette.text, palette.bg)
  line(" " .. val)
end

function terminal.spacer()
  line("")
end

function terminal.menu(items)
  terminal.section("Available Actions")
  for index, item in ipairs(items) do
    setColors(palette.accent, palette.bg)
    write(string.format("%d. ", index))
    setColors(palette.text, palette.bg)
    line(safeText(item.label, contentWidth() - 3))
  end

  terminal.spacer()
  setColors(palette.dim, palette.bg)
  line("Enter a selection number and press return.")
  resetColors()
  write("Selection > ")
  local raw = io.read()
  return tonumber(raw or "")
end

function terminal.prompt(label)
  setColors(palette.dim, palette.bg)
  write((label or "Input") .. " > ")
  resetColors()
  return io.read()
end

function terminal.pause(label)
  terminal.spacer()
  setColors(palette.dim, palette.bg)
  write((label or "Press enter to continue.") .. " ")
  resetColors()
  io.read()
end

return terminal
