dofile("Bootstrap.lua");
dofile("TestingBootstrap.lua");
local APIServer = require "APIServer";
local fileServlet = require("FileServlet"):new();
APIServer:new {port = 8080, servlets = {file = fileServlet} }:start();
local client = MockConnection:new();

test("Post file single packet", function()
  net.server:connect(client);
  client:receive("POST /servlet/file/test1.txt HTTP/1.1\nContent-Length: 30\r\n\r\n****** File Upload Data 1 ******");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals("****** File Upload Data 1 ******", file.open("test1.txt"):read());
end);

test("Post file data in single seperate packet", function()
  net.server:connect(client);
  client:receive("POST /servlet/file/test2.txt HTTP/1.1\nContent-Length: 30");
  client:receive("****** File Upload Data 2 ******");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals("****** File Upload Data 2 ******", file.open("test2.txt"):read());
end);

test("Post File Data in dual seperate packets", function()
  net.server:connect(client);
  client:receive("POST /servlet/file/test3.txt HTTP/1.1\nContent-Length: 58");
  client:receive("****** File Upload Data 3 *****");
  client:receive("****** Additional Data ********");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  local fd = file.open("test3.txt");
  assertEquals("****** File Upload Data 3 *****", fd:read());
  assertEquals("****** Additional Data ********", fd:read());
end);

test("Get file 1", function()
  net.server:connect(client);
  client:receive("GET /servlet/file/test1.txt HTTP/1.1");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals("****** File Upload Data 1 ******", client.messages[2]);
end);

test("Get file 2", function()
  net.server:connect(client);
  client:receive("GET /servlet/file/test2.txt HTTP/1.1");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals("****** File Upload Data 2 ******", client.messages[2]);
end);

test("Get file 3", function()
  net.server:connect(client);
  client:receive("GET /servlet/file/test3.txt HTTP/1.1");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals("****** File Upload Data 3 *****", client.messages[2]);
  assertEquals("****** Additional Data ********", client.messages[3]);
end);

test("List files", function()
  net.server:connect(client);
  client:receive("GET /servlet/file HTTP/1.1");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  local result = sjson.decode(client.messages[2]);
  assertEquals(3, result.totalSize);
end);

test("Delete file", function()
  net.server:connect(client);
  client:receive("DELETE /servlet/file/test2.txt HTTP/1.1");
  assertEquals(true, string.find(client.messages[1], "HTTP/1.1 200 OK") ~= nil);
  assertEquals(nil, file.open("test2.txt", "r"));
end);