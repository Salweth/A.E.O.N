return {
  installRoot = "/aeon",
  stubPath = "/bin/aeon",
  installVersion = "2.0.0-alpha",
  directories = {
    "/aeon",
    "/aeon/bin",
    "/aeon/lib",
    "/aeon/apps",
    "/aeon/data",
    "/aeon/config",
    "/aeon/runtime",
    "/aeon/install"
  },
  notes = {
    "All AEON application files live under /aeon.",
    "The only root-level entry point is the /bin/aeon launcher stub.",
    "Optional device integrations must not block core OS startup.",
    "This package targets an agent workstation, not an administrative server.",
    "Apps are modular and may be installed depending on workstation role and equipment."
  }
}
