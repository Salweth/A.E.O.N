local term = require("term")

local terminal = {}

local function line(text)
  io.write(tostring(text or "") .. "\n")
end

function terminal.clear()
  term.clear()
  term.setCursor(1, 1)
end

function terminal.header(title, subtitle)
  terminal.clear()
  line("========================================")
  line("AEON OPERATIVE WORKSTATION")
  line("========================================")
  line(title or "Main")
  if subtitle and subtitle ~= "" then
    line(subtitle)
  end
  line("----------------------------------------")
end

function terminal.info(text)
  line("[INFO] " .. tostring(text or ""))
end

function terminal.warn(text)
  line("[WARN] " .. tostring(text or ""))
end

function terminal.error(text)
  line("[ERR ] " .. tostring(text or ""))
end

function terminal.menu(items)
  for index, item in ipairs(items) do
    line(string.format("%d. %s", index, item.label))
  end

  line("")
  io.write("Selection > ")
  local raw = io.read()
  return tonumber(raw or "")
end

function terminal.pause(label)
  line("")
  io.write((label or "Press enter to continue.") .. " ")
  io.read()
end

return terminal
