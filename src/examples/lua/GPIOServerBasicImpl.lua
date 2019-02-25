local APIServer = require "APIServer"
local resourceServlet = require "ResourceServlet"

local function setMode(entity)
  if (entity.mode == "INPUT") then
    gpio.mode(entity.id, gpio.INT)
    gpio.trig(entity.id, function(level, when)
      entity.value = level
    end)
  else
    gpio.mode(entity.id, gpio.OUTPUT)
  end
end

local gpioService = {
  entities = {},
  create = function(self, createRequest)
    local entity = createRequest.entity
    setMode(entity)
    self.entities[entity.id] = entity
    return entity
  end,
  get = function(self, getRequest)
    local entity = self.entities[getRequest.id]
    if (entity == nil) then
      return {_errorCode = 404, _message = "Not Found"}
    end
    return entity
  end,
  list = function(self, listRequest)
    local results = {}
    for k, entity in pairs(self.entities) do
      results[#results + 1] = entity
    end
    return {result = results, totalSize = #results}
  end,
  update = function(self, updateRequest)
    local entity = self.entities[updateRequest.id]
    if (entity == nil) then
      return {_errorCode = 404, _message = "Not Found"}
    end
    for i = 1, #updateRequest.updateMask do
      local property = updateRequest.updateMask[i]
      entity[property] = updateRequest.entity[property]
      if (property == "mode") then
        setMode(entity)
      end
      if (property == "value") then
        gpio.write(entity.id, gpio[entity.value])
      end
    end
    return entity
  end,
  delete = function(self, deleteRequest)
    self.entities[deleteRequest.id] = nil
    return {}
  end
}

local server = APIServer:new{port = 80, services = {gpios = gpioService}, resourceServlet = resourceServlet}
server:start()
