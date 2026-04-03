return {
  run = function(context)
    local ui = context.ui
    local storage = context.services.storage
    local devices = context.services.devices

    ui.header("Documents", "Field access console")
    ui.info("Data root: " .. tostring(storage:path("documents")))
    ui.info("Document system V2 is not implemented yet.")
    if devices:isAvailable("printer") then
      ui.info("Printer integration is available.")
    else
      ui.warn("Printer integration is not available on this workstation.")
    end
    ui.pause()
  end
}
