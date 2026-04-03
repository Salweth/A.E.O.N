local appRegistryFactory = require("aeon.core.app_registry")
local serviceRegistryFactory = require("aeon.core.service_registry")
local terminal = require("aeon.ui.terminal")
local configServiceFactory = require("aeon.services.config")
local loggerServiceFactory = require("aeon.services.logger")
local runtimeServiceFactory = require("aeon.services.runtime")
local storageServiceFactory = require("aeon.services.storage")
local devicesServiceFactory = require("aeon.services.devices")
local appsServiceFactory = require("aeon.services.apps")

local launcher = {}

local function buildSession(config)
  local workstation = config.workstation or {}
  local agent = config.agent or {}

  return {
    workstationId = workstation.id or "unknown-workstation",
    workstationRole = workstation.role or "field-agent",
    agentName = agent.name or "unassigned",
    agentClearance = agent.clearance or "standard"
  }
end

local function buildContext(services, session)
  return {
    session = session,
    services = services:all(),
    runtime = services:require("runtime"),
    ui = terminal,
    logger = services:require("logger")
  }
end

local function registerCoreServices()
  local services = serviceRegistryFactory.create()
  services:register("config", configServiceFactory.create("/aeon/config"))
  services:register("logger", loggerServiceFactory.create("/aeon/runtime/logs"))
  services:register("runtime", runtimeServiceFactory.create("/aeon/runtime"))
  services:register("storage", storageServiceFactory.create("/aeon/data"))
  services:register("devices", devicesServiceFactory.create())
  services:register("apps", appsServiceFactory.create("/aeon/config"))
  return services
end

local function initCoreServices(services)
  services:require("config"):init()
  services:require("runtime"):init()
  services:require("storage"):init()
  services:require("apps"):init()
  services:require("logger"):info("AEON core services initialized.")
end

local function renderHome(session, apps, devices)
  terminal.header("Agent Workstation", string.format("Agent: %s | Workstation: %s", session.agentName, session.workstationId))
  terminal.info("Role: " .. tostring(session.workstationRole))
  terminal.info("Clearance: " .. tostring(session.agentClearance))
  terminal.info("Installed apps: " .. tostring(#apps))
  terminal.info("Devices online: glasses=" .. tostring(devices:isAvailable("glasses")) .. ", printer=" .. tostring(devices:isAvailable("printer")) .. ", scanner=" .. tostring(devices:isAvailable("scanner")))
  io.write("\n")
end

local function runApp(entry, context)
  if type(entry) == "table" and type(entry.run) == "function" then
    return pcall(entry.run, context)
  end

  if type(entry) == "function" then
    return pcall(entry, context)
  end

  return false, "Invalid app entry point."
end

local function manageApplications(appRegistry, appsService, logger)
  while true do
    local catalog = appsService:listCatalog(appRegistry.apps)
    terminal.header("Application Manager", "Enable or disable workstation apps")

    for index, app in ipairs(catalog) do
      local status = app.enabled and "enabled" or "disabled"
      local defaultTag = app.defaultInstalled and "default" or "optional"
      terminal.info(string.format("%d. %s [%s] (%s)", index, app.name, status, defaultTag))
    end

    io.write("\n")
    io.write("Select app number to toggle, or press enter to return > ")
    local raw = io.read()
    if raw == nil or raw == "" then
      return
    end

    local choice = tonumber(raw)
    local selected = choice and catalog[choice]
    if not selected then
      terminal.warn("Invalid application selection.")
      terminal.pause()
    else
      local enabled, err = appsService:toggleEnabled(selected.id)
      if not enabled and err then
        terminal.error("Unable to update app state: " .. tostring(err))
      else
        logger:info("App state changed: " .. tostring(selected.id) .. " enabled=" .. tostring(enabled))
        terminal.info(selected.name .. " is now " .. (enabled and "enabled" or "disabled") .. ".")
      end
      terminal.pause()
    end
  end
end

function launcher.run()
  local services = registerCoreServices()
  initCoreServices(services)

  local config = services:require("config"):getAll()
  local session = buildSession(config)
  services:require("runtime"):setSession(session)

  local context = buildContext(services, session)
  local apps = appRegistryFactory.create("/aeon/apps")
  apps:scan()
  services:require("apps"):syncCatalog(apps.apps)

  while true do
    apps:scan()
    services:require("apps"):syncCatalog(apps.apps)
    local launchableApps = services:require("apps"):listLaunchable(apps.apps)
    renderHome(session, launchableApps, services:require("devices"))

    local menuItems = {}
    for _, app in ipairs(launchableApps) do
      table.insert(menuItems, {
        label = (app.launcher and app.launcher.label) or app.name or app.id
      })
    end
    table.insert(menuItems, {label = "Application manager"})
    table.insert(menuItems, {label = "System status"})
    table.insert(menuItems, {label = "Exit"})

    terminal.info("Main menu")
    io.write("\n")
    local choice = terminal.menu(menuItems)
    if not choice then
      terminal.warn("Invalid selection.")
      terminal.pause()
    elseif choice >= 1 and choice <= #launchableApps then
      local app = launchableApps[choice]
      local manifest, entry = apps:load(app.id)
      if not manifest then
        terminal.error(entry)
        terminal.pause()
      else
        services:require("logger"):info("Launching app: " .. tostring(app.id))
        local ok, err = runApp(entry, context)
        if not ok then
          services:require("logger"):error("Application crash: " .. tostring(err))
          terminal.error("Application error: " .. tostring(err))
          terminal.pause()
        end
      end
    elseif choice == (#launchableApps + 1) then
      manageApplications(apps, services:require("apps"), services:require("logger"))
    elseif choice == (#launchableApps + 2) then
      terminal.header("System Status", "Core workstation services")
      terminal.info("Storage root: /aeon/data")
      terminal.info("Config root: /aeon/config")
      terminal.info("Runtime root: /aeon/runtime")
      terminal.info("App root: /aeon/apps")
      terminal.info("Apps config: /aeon/config/apps.cfg")
      terminal.pause()
    elseif choice == (#launchableApps + 3) then
      terminal.clear()
      return
    else
      terminal.warn("Unknown selection.")
      terminal.pause()
    end
  end
end

return launcher
