local okComponent, component = pcall(require, "component")
local okComputer, computer = pcall(require, "computer")

local audioService = {}

local function componentProxy(kind)
  if not okComponent or not component or not component.list then
    return nil
  end

  local address = component.list(kind)()
  if not address then
    return nil
  end

  return component.proxy(address), address
end

function audioService.create()
  local service = {
    backend = "none",
    proxy = nil,
    address = nil
  }

  function service:init()
    local soundProxy, soundAddress = componentProxy("sound")
    if soundProxy then
      self.backend = "sound"
      self.proxy = soundProxy
      self.address = soundAddress
      return true
    end

    local noiseProxy, noiseAddress = componentProxy("noise")
    if noiseProxy then
      self.backend = "noise"
      self.proxy = noiseProxy
      self.address = noiseAddress
      return true
    end

    local beepProxy, beepAddress = componentProxy("beep")
    if beepProxy then
      self.backend = "beep"
      self.proxy = beepProxy
      self.address = beepAddress
      return true
    end

    if okComputer and computer and computer.beep then
      self.backend = "computer"
      return true
    end

    self.backend = "none"
    return false
  end

  function service:isAvailable()
    return self.backend ~= "none"
  end

  function service:emitComputer(freq, duration)
    if okComputer and computer and computer.beep then
      pcall(computer.beep, freq or 880, duration or 0.05)
      return true
    end
    return false
  end

  function service:emitBeepCard(freq, duration)
    if self.proxy and self.proxy.beep then
      local ok = pcall(self.proxy.beep, freq or 880, duration or 0.05)
      return ok
    end
    return false
  end

  function service:emitNoiseCard(freq, duration)
    if self.proxy and self.proxy.beep then
      local ok = pcall(self.proxy.beep, freq or 880, duration or 0.05)
      if ok then
        return true
      end
    end
    return self:emitComputer(freq, duration)
  end

  function service:emitSoundCard(freq, duration)
    if self.proxy and self.proxy.beep then
      local ok = pcall(self.proxy.beep, freq or 880, duration or 0.05)
      if ok then
        return true
      end
    end
    return self:emitComputer(freq, duration)
  end

  function service:play(freq, duration)
    if self.backend == "sound" then
      return self:emitSoundCard(freq, duration)
    elseif self.backend == "noise" then
      return self:emitNoiseCard(freq, duration)
    elseif self.backend == "beep" then
      return self:emitBeepCard(freq, duration)
    elseif self.backend == "computer" then
      return self:emitComputer(freq, duration)
    end
    return false
  end

  function service:focus()
    return self:play(1046, 0.03)
  end

  function service:click()
    local ok = self:play(1318, 0.04)
    self:play(1567, 0.03)
    return ok
  end

  function service:error()
    local ok = self:play(440, 0.07)
    self:play(330, 0.08)
    return ok
  end

  function service:confirm()
    local ok = self:play(988, 0.04)
    self:play(1318, 0.05)
    return ok
  end

  service:init()
  return service
end

return audioService
