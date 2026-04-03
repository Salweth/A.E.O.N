return {
  id = "documents",
  name = "Documents",
  version = "2.0.0-alpha",
  entry = "/aeon/apps/documents/main.lua",
  category = "records",
  description = "Document access for field agents.",
  requires = {"storage"},
  optionalDevices = {"printer", "scanner"},
  defaultInstalled = true,
  launcher = {
    label = "Documents",
    order = 20
  }
}
