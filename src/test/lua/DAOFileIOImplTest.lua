dofile("Bootstrap.lua")
dofile("TestingBootstrap.lua")
local DAO = require "DAOFileIOImpl"
dao = DAO:new()
dofile("DAOTests.lua")
