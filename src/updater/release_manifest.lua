return {
  version = "2.0.0-alpha",
  repo = "Salweth/A.E.O.N",
  branch = "main",
  directories = {
    "/aeon",
    "/aeon/apps",
    "/aeon/apps/documents",
    "/aeon/apps/missions",
    "/aeon/bin",
    "/aeon/config",
    "/aeon/data",
    "/aeon/install",
    "/aeon/lib",
    "/aeon/lib/aeon",
    "/aeon/lib/aeon/core",
    "/aeon/lib/aeon/services",
    "/aeon/lib/aeon/ui",
    "/aeon/runtime",
    "/bin"
  },
  files = {
    {
      source = "src/rootfs/bin/aeon",
      target = "/bin/aeon"
    },
    {
      source = "src/rootfs/aeon/bin/aeon.lua",
      target = "/aeon/bin/aeon.lua"
    },
    {
      source = "src/rootfs/aeon/apps/documents/main.lua",
      target = "/aeon/apps/documents/main.lua"
    },
    {
      source = "src/rootfs/aeon/apps/documents/manifest.lua",
      target = "/aeon/apps/documents/manifest.lua"
    },
    {
      source = "src/rootfs/aeon/apps/missions/main.lua",
      target = "/aeon/apps/missions/main.lua"
    },
    {
      source = "src/rootfs/aeon/apps/missions/manifest.lua",
      target = "/aeon/apps/missions/manifest.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/core/app_registry.lua",
      target = "/aeon/lib/aeon/core/app_registry.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/core/launcher.lua",
      target = "/aeon/lib/aeon/core/launcher.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/core/service_registry.lua",
      target = "/aeon/lib/aeon/core/service_registry.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/services/config.lua",
      target = "/aeon/lib/aeon/services/config.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/services/devices.lua",
      target = "/aeon/lib/aeon/services/devices.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/services/logger.lua",
      target = "/aeon/lib/aeon/services/logger.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/services/runtime.lua",
      target = "/aeon/lib/aeon/services/runtime.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/services/storage.lua",
      target = "/aeon/lib/aeon/services/storage.lua"
    },
    {
      source = "src/rootfs/aeon/lib/aeon/ui/terminal.lua",
      target = "/aeon/lib/aeon/ui/terminal.lua"
    }
  }
}
