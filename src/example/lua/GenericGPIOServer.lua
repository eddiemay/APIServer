local APIServer = require "APIServer"
local APIService = require "GenericService"
local GenericStore = require "GenericStore"
local DAO = require "DAOInMemoryImpl"
local resourceServlet = require "ResourceServlet"

local store = GenericStore:new { name = "gpio", dao = DAO:new() }
local gpioService = APIService:new { store = store }
store.create = function(self, entity)
  gpio.mode(entity.id, gpio[entity.mode])
  if (entity.mode == "INT") then
    gpio.trig(entity.id, function(level, when)
      entity.value = level
    end)
  end
  return self.super.create(self, entity)
end
store.get = function(self, getRequest)
  local port = self.super.get(self, getRequest)
  if (port ~= nil and port.mode == "INPUT") then
    port.value = gpio.read(port.id)
  end
  return port
end
store.list = function(self, query)
  local listResponse = self.super.list(self, query)
  for i = 1, #listResponse.result do
    local port = listResponse.result[i]
    if (port.mode == gpio.INPUT) then
      port.value = gpio.read(port.id)
    end
  end
  return listResponse
end
store.update = function(self, id, updater)
  return self.super.update(self, id, function(current)
    local updated = updater(current)
    if (updated.mode ~= current.mode) then
      gpio.mode(updated.id, gpio[updated.mode])
    end
    if (updated.value ~= current.value) then
      gpio.write(updated.id, gpio[updated.value])
    end
    return updated
  end)
end

local server = APIServer:new { port = 8080, services = { gpios = gpioService }, resourceServlet = resourceServlet }
server:start()
