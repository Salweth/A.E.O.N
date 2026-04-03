return {
  id = "missions",
  name = "Missions",
  version = "2.0.0-alpha",
  entry = "/aeon/apps/missions/main.lua",
  category = "operations",
  description = "Mission access for field agents.",
  requires = {"storage", "config"},
  optionalDevices = {"glasses"},
  defaultInstalled = true,
  launcher = {
    label = "Missions",
    order = 10
  }
}
