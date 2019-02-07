dofile("Bootstrap.lua")
dofile("TestingBootstrap.lua")
local DAO = require "DAOInMemoryImpl"
local GenericStore = require "GenericStore"
local GenericService = require "GenericService"
local APIServer = require "APIServer"
local dao = DAO:new()
local carService = GenericService:new{store = GenericStore:new{name = "car", dao = dao } }
local driverService = GenericService:new { store = GenericStore:new { name = "driver", dao = dao } }
local apiServer = APIServer:new { port = 8080, services = { cars = carService, drivers = driverService } }
apiServer:start()
local client = MockConnection:new()

test("Parse Basic GetRequest", function()
  local httpRequest = APIServer.parseRequest("GET /api/cars/5 HTTP/1.1")
  assertEquals("GET", httpRequest.method)
  assertEquals("/api/cars/5", httpRequest.path)
  assertEquals(nil, next(httpRequest.parameters))
end)

test("Parse GetRequest with vars", function()
  local httpRequest = APIServer.parseRequest("GET /api/cars?limit=5&offset=10 HTTP/1.1")
  assertEquals("GET", httpRequest.method)
  assertEquals("/api/cars", httpRequest.path)
  assertEquals(5, httpRequest.parameters.limit)
  assertEquals(10, httpRequest.parameters.offset)
end)

test("Parse PostRequest single packet", function()
  local post = "POST /api/cars HTTP/1.1\nHost: 192.168.4.1\nConnection: keep-alive\r\n\r\n{\"entity\":{\"engine\":\"v6\"}}"
  local httpRequest = APIServer.parseRequest(post)
end)

test("ToAPIRequest", function()
  local apiRequest = APIServer.toAPIRequest { method = "GET", path = "/api/cars/5" }
  assertEquals("cars", apiRequest._resource)
  assertEquals("get", apiRequest._action)
  assertEquals(5, apiRequest.id)
  assertEquals(nil, customAction)

  apiRequest = APIServer.toAPIRequest { method = "PUT", path = "/api/drivers" }
  assertEquals("drivers", apiRequest._resource)
  assertEquals("create", apiRequest._action)
  assertEquals(nil, apiRequest.id)
  assertEquals(nil, customAction)

  apiRequest = APIServer.toAPIRequest { method = "GET", path = "/api/year/2017/month/10/bills" }
  assertEquals("bills", apiRequest._resource)
  assertEquals("list", apiRequest._action)
  assertEquals(2017, apiRequest.year)
  assertEquals(10, apiRequest.month)
  assertEquals(nil, apiRequest.id)
  assertEquals(nil, customAction)

  apiRequest = APIServer.toAPIRequest { method = "POST", path = "/api/users/17:clearCars" }
  assertEquals("users", apiRequest._resource)
  assertEquals("clearCars", apiRequest._action)
  assertEquals(17, apiRequest.id)

  apiRequest = APIServer.toAPIRequest { method = "POST", path = "/api/users:sync"}
  assertEquals("users", apiRequest._resource)
  assertEquals("sync", apiRequest._action)
  assertEquals(nil, apiRequest.id)
end)

test("UnknownService", function()
  local result = apiServer:doAPIRequest { _resource = "unknown", _action = "create", entity = { year = 2004, make = "JAG", model = "XJR" } }
  assertEquals(404, result._errorCode)
  assertEquals("Not Found", result._message)

  net.server:connect(client)
  client:receive("GET /api/unknown HTTP/1.1")
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 404 Not Found") ~= nil)
end)

test("CreateRequest", function()
  local jag = apiServer:doAPIRequest { _resource = "cars", _action = "create", entity = { year = 2004, make = "Jaguar", model = "XJR" } }
  assertEquals(1000, jag.id)
  assertEquals(2004, jag.year)
  assertEquals("Jaguar", jag.make)
  assertEquals("XJR", jag.model)

  net.server:connect(client)
  client:receive("PUT /api/cars HTTP/1.1")
  client:receive("{\"entity\":{\"year\":2013,\"make\":\"BMW\",\"model\":\"s1000RR\"}}")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  local bmw = sjson.decode(client.messages[2])
  assertEquals(1001, bmw.id)
  assertEquals(2013, bmw.year)
  assertEquals("BMW", bmw.make)
  assertEquals("s1000RR", bmw.model)

  local driver = apiServer:doAPIRequest { _resource = "drivers", _action = "create", entity = { name = "Eddie Mayfield", licenses = { "c", "m1" } } }
  assertEquals(1000, driver.id)
  assertEquals("Eddie Mayfield", driver.name)
  assertEquals(2, #driver.licenses)
end)

test("GetRequest", function()
  local jag = apiServer:doAPIRequest { _resource = "cars", _action = "get", id = 1000 }
  assertEquals(1000, jag.id)
  assertEquals(2004, jag.year)
  assertEquals("Jaguar", jag.make)
  assertEquals("XJR", jag.model)

  net.server:connect(client)
  client:receive("GET /api/cars/1001 HTTP/1.1")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  local bmw = sjson.decode(client.messages[2])
  assertEquals(2013, bmw.year)
  assertEquals("BMW", bmw.make)
  assertEquals("s1000RR", bmw.model)

  local driver = apiServer:doAPIRequest { _resource = "drivers", _action = "get", id = 1000 }
  assertEquals(1000, driver.id)
  assertEquals("Eddie Mayfield", driver.name)
  assertEquals(2, #driver.licenses)
end)

test("ListRequest", function()
  local carsResponse = apiServer:doAPIRequest { _resource = "cars", _action = "list" }
  assertEquals(2, #carsResponse.result)
  assertEquals(2, carsResponse.totalSize)
  assertEquals(2004, carsResponse.result[1].year)
  assertEquals("Jaguar", carsResponse.result[1].make)
  assertEquals("XJR", carsResponse.result[1].model)
  assertEquals(2013, carsResponse.result[2].year)
  assertEquals("BMW", carsResponse.result[2].make)
  assertEquals("s1000RR", carsResponse.result[2].model)

  net.server:connect(client)
  client.receive(client, "GET /api/cars HTTP/1.1")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  carsResponse = sjson.decode(client.messages[2])
  assertEquals(2, #carsResponse.result)
  assertEquals(2, carsResponse.totalSize)
  assertEquals(2004, carsResponse.result[1].year)
  assertEquals("Jaguar", carsResponse.result[1].make)
  assertEquals("XJR", carsResponse.result[1].model)
  assertEquals(2013, carsResponse.result[2].year)
  assertEquals("BMW", carsResponse.result[2].make)
  assertEquals("s1000RR", carsResponse.result[2].model)

  carsResponse = apiServer:doAPIRequest { _resource = "cars", _action = "list", pageSize = 1 }
  assertEquals(1, #carsResponse.result)
  assertEquals(2, carsResponse.totalSize)
  assertEquals(2004, carsResponse.result[1].year)
  assertEquals("Jaguar", carsResponse.result[1].make)
  assertEquals("XJR", carsResponse.result[1].model)

  net.server:connect(client)
  client.receive(client, "GET /api/cars?pageSize=1 HTTP/1.1")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  carsResponse = sjson.decode(client.messages[2])
  assertEquals(1, #carsResponse.result)
  assertEquals(2, carsResponse.totalSize)
  assertEquals(2004, carsResponse.result[1].year)
  assertEquals("Jaguar", carsResponse.result[1].make)
  assertEquals("XJR", carsResponse.result[1].model)

  carsResponse = apiServer:doAPIRequest { _resource = "cars", _action = "list", pageToken = 1 }
  assertEquals(1, #carsResponse.result)
  assertEquals(2, carsResponse.totalSize)
  assertEquals(2013, carsResponse.result[1].year)
  assertEquals("BMW", carsResponse.result[1].make)
  assertEquals("s1000RR", carsResponse.result[1].model)
end)

test("UpdateRequest", function()
  local jag = apiServer:doAPIRequest { _resource = "cars", _action = "update", id = 1000, entity = { engine = "V8 Super Charged" }, updateMask = { "engine" } }
  assertEquals(2004, jag.year)
  assertEquals("Jaguar", jag.make)
  assertEquals("XJR", jag.model)
  assertEquals("V8 Super Charged", jag.engine)

  net.server:connect(client)
  client:receive("PATCH /api/cars/1001 HTTP/1.1")
  client:receive("{\"entity\": {\"engine\": \"1000cc\"}, \"updateMask\": [\"engine\"]}")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  local bmw = sjson.decode(client.messages[2])
  assertEquals(2013, bmw.year)
  assertEquals("BMW", bmw.make)
  assertEquals("s1000RR", bmw.model)
  assertEquals("1000cc", bmw.engine)
end)

test("UpdateRequest Single Message", function()
  net.server:connect(client)
  client:receive("PATCH /api/cars/1001 HTTP/1.1\r\n\r\n{\"entity\":{\"engine\":\"999cc\"},\"updateMask\":[\"engine\"]}")
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1])
  local bmw = sjson.decode(client.messages[2])
  assertEquals(2013, bmw.year)
  assertEquals("BMW", bmw.make)
  assertEquals("s1000RR", bmw.model)
  assertEquals("999cc", bmw.engine)
end)

test("DeleteRequest", function()
  apiServer:doAPIRequest { _resource = "cars", _action = "delete", id = 1001 }
  local carsResponse = apiServer:doAPIRequest { _resource = "cars", _action = "list" }
  assertEquals(1, #carsResponse.result)
  assertEquals(1, carsResponse.totalSize)

  net.server:connect(client)
  client:receive("DELETE /api/cars/1000 HTTP/1.1")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  assertEquals("[]", client.messages[2])

  net.server:connect(client)
  client:receive("GET /api/cars HTTP/1.1")
  assertEquals("HTTP/1.1 200 OK", string.sub(client.messages[1], 1, 15))
  assertEquals(0, sjson.decode(client.messages[2]).totalSize)
end)
