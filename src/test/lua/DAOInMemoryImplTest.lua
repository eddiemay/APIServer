dofile("Bootstrap.lua")
dofile("TestingBootstrap.lua")
local DAO = require "DAOInMemoryImpl"
dao = DAO:new()
dofile("DAOTests.lua")
