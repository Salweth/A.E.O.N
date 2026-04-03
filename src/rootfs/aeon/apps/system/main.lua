local function readVersion()
  local handle = io.open("/aeon/config/version.txt", "r")
  if not handle then
    return "unknown"
  end

  local value = handle:read("*a")
  handle:close()
  value = tostring(value or ""):gsub("%s+$", "")
  if value == "" then
    return "unknown"
  end
  return value
end

return {
  run = function(context)
    local ui = context.ui
    local session = context.session
    local config = context.services.config
    local runtime = context.services.runtime
    local devices = context.services.devices
    local apps = context.services.apps

    local allConfig = config:getAll()
    local workstation = allConfig.workstation or {}
    local agent = allConfig.agent or {}
    local runtimeSession = runtime:getSession() or {}
    local catalog = {}

    if apps and type(apps.listCatalog) == "function" then
      for _, app in ipairs(apps:listCatalog(context.appCatalog or {})) do
        table.insert(catalog, app)
      end
    end

    ui.header("System", "Local workstation status")
    ui.info("Installed version: " .. tostring(readVersion()))
    ui.info("Workstation id: " .. tostring(workstation.id or session.workstationId))
    ui.info("Workstation role: " .. tostring(workstation.role or session.workstationRole))
    ui.info("Agent: " .. tostring(agent.name or session.agentName))
    ui.info("Clearance: " .. tostring(agent.clearance or session.agentClearance))
    ui.info("Runtime session agent: " .. tostring(runtimeSession.agentName or "unknown"))
    ui.info("Devices: glasses=" .. tostring(devices:isAvailable("glasses")) .. ", printer=" .. tostring(devices:isAvailable("printer")) .. ", scanner=" .. tostring(devices:isAvailable("scanner")))
    ui.info("Apps service available: " .. tostring(apps ~= nil))
    ui.info("Apps registered: " .. tostring(#catalog))

    for _, app in ipairs(catalog) do
      ui.info(string.format("App %s: installed=%s enabled=%s", app.name, tostring(app.installed), tostring(app.enabled)))
    end

    ui.pause()
  end
}
