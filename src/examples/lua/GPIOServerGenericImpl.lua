local APIServer = require "APIServer"
local APIService = require "GenericService"
local GenericStore = require "GenericStore"
local DAO = require "DAOInMemoryImpl"
local resourceServlet = require "ResourceServlet"

local store = GenericStore:new{name = "gpio", dao = DAO:new()}
local gpioService = APIService:new{store = store}
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
store.create = function(self, entity)
  setMode(entity)
  return self.super.create(self, entity)
end
store.update = function(self, id, updater)
  return self.super.update(self, id, function(current)
    local updated = updater(current)
    if (updated.mode ~= current.mode) then
      setMode(updated)
    end
    if (updated.mode == "OUTPUT" and updated.value ~= current.value) then
      gpio.write(updated.id, gpio[updated.value])
    end
    return updated
  end)
end

local server = APIServer:new{port = 8080, services = {gpios = gpioService}, resourceServlet = resourceServlet}
server:start()
