dofile("Bootstrap.lua");
dofile("TestingBootstrap.lua");
local APIServer = require "APIServer";
local resourceServlet = require "ResourceServlet";

local apiServer = APIServer:new{port = 8080, resourceServlet = resourceServlet};
apiServer:start();
local client = MockConnection:new();

local INDEX_HTML_CONTENT = "<html><body><h1>Hello World</h1></body></html>";
file.open("index.html", "w"):writeline(INDEX_HTML_CONTENT);

local JS_ROOT_FILE_CONTENT = "<script type='javascript'>print('Hello from root')</script>";
file.open("root.js", "w"):writeline(JS_ROOT_FILE_CONTENT);

local JS_DIR_FILE_CONTENT = "<script type='javascript'>print('Hello from Directory')</script>";
file.open("js/directory.js", "w"):writeline(JS_DIR_FILE_CONTENT);

local GZIP_FILE_CONTENT = "gzip data #$#";
file.open("site.js.gz", "w"):writeline(GZIP_FILE_CONTENT);

local LONG_FILENAME_CONTENT = "gzip long file content";
file.open("file_with_a_lon_file_name.js.gz", "w"):writeline(LONG_FILENAME_CONTENT);

test("GET index.html", function()
  net.server:connect(client);
  client:receive("GET /index.html HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(INDEX_HTML_CONTENT, client.messages[2]);
end);

test("GET / should return index.html", function()
  net.server:connect(client);
  client:receive("GET / HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(INDEX_HTML_CONTENT, client.messages[2]);
end);

test("Request a file that does not exist returns 404", function()
  net.server:connect(client);
  client:receive("GET /unknown.file HTTP/1.1");
  assertStartsWith("HTTP/1.1 404 Not Found", client.messages[1]);
end);

test("Can get a js file in the root directory", function()
  net.server:connect(client);
  client:receive("GET /root.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(JS_ROOT_FILE_CONTENT, client.messages[2]);
end);

test("Can get a js file in a directory", function()
  net.server:connect(client);
  client:receive("GET /js/directory.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(JS_DIR_FILE_CONTENT, client.messages[2]);
end);

test("Trying to load the root.js file from a directory results in the root file", function()
  net.server:connect(client);
  client:receive("GET /js/root.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(JS_ROOT_FILE_CONTENT, client.messages[2]);

  net.server:connect(client);
  client:receive("GET /path/to/js/root.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  assertEquals(JS_ROOT_FILE_CONTENT, client.messages[2]);
end);

test("Can get a gzip file from root", function()
  net.server:connect(client);
  client:receive("GET /site.js.gz HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  -- assertContains("Content-Type: application/javascript", client.messages[1]);
  -- assertContains("Content-Encoding: gzip", client.messages[1]);
  assertEquals(GZIP_FILE_CONTENT, client.messages[2]);
end);

test("Can get a gzip version of a requested", function()
  net.server:connect(client);
  client:receive("GET /site.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  -- assertContains("Content-Type: application/javascript", client.messages[1]);
  -- assertContains("Content-Encoding: gzip", client.messages[1]);
  assertEquals(GZIP_FILE_CONTENT, client.messages[2]);
end);

test("Can get a gzip version of a requested from root", function()
  net.server:connect(client);
  client:receive("GET /javascript/site.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  -- assertContains("Content-Type: application/javascript", client.messages[1]);
  -- assertContains("Content-Encoding: gzip", client.messages[1]);
  assertEquals(GZIP_FILE_CONTENT, client.messages[2]);
end);

test("Can get a file with a really long name", function()
  net.server:connect(client);
  client:receive("GET /really/long/path/to/a/file_with_a_long_ass_file_name.js HTTP/1.1");
  assertStartsWith("HTTP/1.1 200 OK", client.messages[1]);
  -- assertContains("Content-Type: application/javascript", client.messages[1]);
  -- assertContains("Content-Encoding: gzip", client.messages[1]);
  assertEquals(LONG_FILENAME_CONTENT, client.messages[2]);
end);