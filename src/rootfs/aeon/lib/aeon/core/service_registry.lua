local serviceRegistry = {}

function serviceRegistry.create()
  local registry = {
    _services = {}
  }

  function registry:register(name, service)
    if not name or name == "" then
      return nil, "Service name is required."
    end

    self._services[name] = service
    return true
  end

  function registry:get(name)
    return self._services[name]
  end

  function registry:require(name)
    local service = self:get(name)
    if service == nil then
      error("Missing required service: " .. tostring(name))
    end
    return service
  end

  function registry:all()
    return self._services
  end

  return registry
end

return serviceRegistry
