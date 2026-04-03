local devicesService = {}

function devicesService.create()
  local service = {
    available = {
      glasses = false,
      printer = false,
      scanner = false
    }
  }

  function service:isAvailable(name)
    return self.available[name] == true
  end

  function service:list()
    return self.available
  end

  return service
end

return devicesService
