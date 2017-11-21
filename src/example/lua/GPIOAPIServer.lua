local APIServer = require "APIServer"
local resourceServlet = require "ResourceServlet"

local gpioService = {
  ports = {},
  create = function(self, createRequest)
    local port = createRequest.entity
    gpio.mode(port.id, gpio[port.mode])
    if (port.mode == "INT") then
      gpio.trig(port.id, function(level, when)
        port.value = level
      end)
    end
    self.ports[port.id] = port
    return port
  end,

  get = function(self, getRequest)
    local port = self.ports[getRequest.id]
    if (port == nil) then
      return { _errorCode = 404, _message = "Not Found" }
    end
    if (port.mode == "INPUT") then
      port.value = gpio.read(port.id)
    end
    return port
  end,

  list = function(self, listRequest)
    local ret = { result = {} }
    for k, port in pairs(self.ports) do
      if (port.mode == gpio.INPUT) then
        port.value = gpio.read(port.id)
      end
      ret.result[#ret.result + 1] = port
    end
    ret.totalSize = #ret.result
    return ret
  end,

  update = function(self, updateRequest)
    local port = self.ports[updateRequest.id]
    if (port == nil) then
      return { _errorCode = 404, _message = "Not Found" }
    end
    for i = 1, #updateRequest.updateMask do
      local property = updateRequest.updateMask[i]
      if (property == "mode") then
        gpio.mode(port.id, gpio[updateRequest.entity.mode])
      end
      if (property == "value") then
        gpio.write(port.id, gpio[updateRequest.entity.value])
      end
      port[property] = updateRequest.entity[property]
    end
    return port
  end,

  delete = function(self, deleteRequest)
    self.ports[deleteRequest.id] = nil
    return {}
  end
}

local server = APIServer:new{port = 8080, services = {gpios = gpioService}, resourceServlet = resourceServlet}
server:start()
