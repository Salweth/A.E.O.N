return {
  id = "files",
  name = "Files",
  version = "2.0.0-alpha",
  entry = "/aeon/apps/documents/main.lua",
  category = "workstation",
  description = "Local workstation file explorer.",
  requires = {"filesystem"},
  optionalDevices = {},
  defaultInstalled = true,
  launcher = {
    label = "Files",
    order = 20
  }
}
