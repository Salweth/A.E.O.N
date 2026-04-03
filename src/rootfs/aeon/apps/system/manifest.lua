return {
  id = "system",
  name = "System",
  version = "2.0.0-alpha",
  entry = "/aeon/apps/system/main.lua",
  category = "core",
  description = "Workstation status and local system information.",
  requires = {"config", "runtime", "devices", "apps"},
  optionalDevices = {},
  defaultInstalled = true,
  launcher = {
    label = "System",
    order = 5
  }
}
