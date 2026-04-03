return {
  run = function(context)
    local ui = context.ui
    local session = context.session
    local devices = context.services.devices

    ui.header("Missions", "Operational console")
    ui.info("Agent: " .. tostring(session.agentName))
    ui.info("Mission system V2 is not implemented yet.")
    ui.info("This app can now be enabled or disabled from the application manager.")
    if devices:isAvailable("glasses") then
      ui.info("AR glasses support is available for mission overlays.")
    else
      ui.warn("AR glasses are not connected on this workstation.")
    end
    ui.pause()
  end
}
