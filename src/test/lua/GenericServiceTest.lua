dofile("Bootstrap.lua")
dofile("TestingBootstrap.lua")
local DAO = require "DAOInMemoryImpl"
local Store = require "GenericStore"
local GenericService = require "GenericService"
local carService

function beforeClass()
  carService = GenericService:new { store = Store:new { name = "car", dao = DAO:new() } }
  assertEquals("car", carService.store.name)
  local listResponse = carService:list {}
  assertEquals(0, #listResponse.result)
  assertEquals(0, listResponse.totalSize)
end
beforeClass()

test("Create", function()
  local car = carService:create { entity = { id = 600, year = 2006, make = "Honda", model = "CBR600RR" } }
  assertEquals(600, car.id)
  assertEquals(2006, car.year)
  assertEquals("Honda", car.make)
  assertEquals("CBR600RR", car.model)
  listResponse = carService:list {}
  assertEquals(1, #listResponse.result)
  assertEquals(1, listResponse.totalSize)

  carService:create { entity = { id = 999, year = 2013, make = "BMW", model = "s1000RR" } }
  listResponse = carService:list {}
  assertEquals(2, #listResponse.result)
  assertEquals(2, listResponse.totalSize)
end)

test("Get", function()
  car = carService:get { id = 999 }
  assertEquals(999, car.id)
  assertEquals(2013, car.year)
  assertEquals("BMW", car.make)
  assertEquals("s1000RR", car.model)

  -- Test overriding get and using the super to fulfil the request.
  local getCalled = false
  carService.get = function(self, getRequest)
    getCalled = true
    return self.super.get(self, getRequest)
  end
  car = carService:get { id = 600 }
  assertEquals(600, car.id)
  assertEquals(2006, car.year)
  assertEquals("Honda", car.make)
  assertEquals("CBR600RR", car.model)
  assertEquals(true, getCalled)
end)

test("List", function()
  listResponse = carService:list { pageSize = 1 }
  assertEquals(1, #listResponse.result)
  assertEquals(2, listResponse.totalSize)

  listResponse = carService:list { pageToken = 1 }
  assertEquals(1, #listResponse.result)
  assertEquals(2, listResponse.totalSize)

  listResponse = carService:list { filter = { { column = "year", value = 2013 } } }
  assertEquals(1, #listResponse.result)
  assertEquals(1, listResponse.totalSize)
  assertEquals(2013, listResponse.result[1].year)

  listResponse = carService:list { filter = { { column = "year", value = 2016 } } }
  assertEquals(0, #listResponse.result)
  assertEquals(0, listResponse.totalSize)

  listResponse = carService:list { filter = { { column = "year", operator = "<=", value = 2010 } } }
  assertEquals(1, #listResponse.result)
  assertEquals(1, listResponse.totalSize)
  assertEquals(2006, listResponse.result[1].year)

  listResponse = carService:list { filter = { { column = "year", operator = "!=", value = 2010 } } }
  assertEquals(2, #listResponse.result)
  assertEquals(2, listResponse.totalSize)
end)

test("Update", function()
  car = carService:update { id = 600, entity = { model = "CBR 600RR" }, updateMask = { "model" } }
  assertEquals(600, car.id)
  assertEquals(2006, car.year)
  assertEquals("Honda", car.make)
  assertEquals("CBR 600RR", car.model)
end)

test("Delete", function()
  carService:delete { id = 600 }
  listResponse = carService:list {}
  assertEquals(1, #listResponse.result)
  assertEquals(1, listResponse.totalSize)
  assertEquals(2013, listResponse.result[1].year)
end)
