function assertEquals(expected, actual, message)
  if (expected ~= actual) then
    error(message or "Assert failure.\nExpected: " .. toString(expected) .. "\n  Actual: " .. toString(actual))
  end
end

function assertStartsWith(expected, actual, message)
  if (actual == nil) then
    error(message or "Assert failure.\nExpected to start with: "..toString(expected).." but is nil")
  elseif (string.find(actual, expected) ~= 1) then
    error(message or "Assert failure.\nExpected: "..toString(actual).." to start with: "..toString(expected))
  end
end

function assertContains(expected, actual, message)
  if (actual == nil) then
    error(message or "Assert failure.\nExpected to contain: "..toString(expected).." but is nil")
  elseif (string.find(actual, expected) == nil) then
    error(message or "Assert failure.\nExpected: "..toString(actual).." to contain: "..toString(expected))
  end
end

function test(description, testFunc, ignore)
  if (not ignore) then
    testFunc()
  end
end

files = {};

FakeFile = {
  fileName = nil,
  purpose = "r",
  lines = {},
  curLine = 0,
  needsReset = false,
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  writeline = function(self, line)
    self:write(line .. "\n");
  end,
  write = function(self, data)
    if self.needsReset then
      self.curLine = 0;
      self.lines = {};
      self.needsReset = false;
    end
    self.curLine = self.curLine + 1;
    self.lines[self.curLine] = data;
    files[self.fileName].size = files[self.fileName].size + string.len(data);
  end,
  readline = function(self)
    if (self.curLine < #self.lines) then
      self.curLine = self.curLine + 1
      return self.lines[self.curLine]
    end
    return nil
  end,
  read = function(self)
    return self:readline()
  end,
  close = function(self)
  end
}

file = file or {
  open = function(name, purpose)
    if (name:len() > 31) then
      error("Files with names longer than 31 chars are not support")
    end
    if ((purpose == "r" or purpose == "r+") and files[name] == nil) then
      return nil;
    end
    files[name] = files[name] or {size = 0, data = FakeFile:new{fileName = name, purpose = purpose or "r", lines = {}}};
    local fd = files[name].data;
    if (purpose == "a") then
      fd.curLine = #fd.lines
    elseif (purpose == "w") then
      fd.curLine = 0
      fd.lines = {}
    else
      fd.curLine = 0
      if (purpose == "r+") then
        fd.needsReset = true
      end
    end
    return fd
  end,

  rename = function(oldName, newName)
    files[newName] = files[oldName];
    files[oldName] = nil;
  end,

  remove = function(name)
    files[name] = nil;
  end,

  list = function()
    local fileList = {};
    for name, file in pairs(files) do
      fileList[name] = file.size;
    end
    return fileList;
  end,

  exists = function(filename)
    return files[filename] ~= nil;
  end
}

sjson = sjson or require "json"

gpio = gpio or {
  IN = 3,
  OUT = 1,
  IN_OUT = 2,
  HIGH = 1,
  LOW = 0,
  FLOATING = 1,
  PULL_UP = 2,
  PULL_DOWN = 3,
  PULL_UP_DOWN = 4,
  pins = {},
  config = function(config)
    if (config.gpio == nil or config.dir == nil) then
      error("gpio and dir are required")
    end
    for p = 1, #config.gpio do
      local pin = config.gpio[p];
      if (config.dir == gpio.OUT and pin >= 34 and pin <= 39) then
        error("GPIO34-39 can only be used as input mode");
      end
      gpio.pins[pin] = gpio.pins[pin] or {}
      gpio.pins[pin].dir = config.dir
    end
  end,
  write = function(pin, value)
    gpio.pins[pin].value = value
  end,
  read = function(pin)
    return gpio.pins[pin].value
  end,
  trig = function(pin, type, callback)
    if (callback == nil) then
      error("callback required")
    end
    gpio.pins[pin][type] = {trig = callback}
    gpio.pins[pin].trig = callback
  end,
  set = function(pin, value)
    pin = gpio.pins[pin]
    pin.value = value
    if (pin.trig) then
      pin.trig(pin.value, 1000)
    end
  end,
}

uart = {
  PARITY_NONE = 0,
  STOPBITS_1 = 1,
  written = {},
  setup = function(index, rate, bits, parity, stopBits, bitRate)
    uart.written[index + 1] = {}
  end,
  write = function(index, data)
    uart.written[index][#uart.written[index] + 1] = data
  end
}

tmr = {
  running = false,
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  create = function()
    return tmr:new()
  end,
  delay = function(millis) end,
  start = function(self)
    self.running = true;
  end,
  register = function(self, interval_ms, mode, func) end,
  unregister = function(self)
    self.running = false;
  end,
}

net = net or {
  TCP = "TCP",
  server = nil,
  createServer = function(protocol)
    net.server = {
      listen = function(self, port, onConnect)
        self.onConnect = onConnect
      end,
      connect = function(self, conn)
        conn.messages = {}
        self.onConnect(conn)
      end
    }
    return net.server
  end
}

MockConnection = {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    o.messages = o.messages or {}
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  on = function(self, action, Function)
    self[action] = Function
  end,
  send = function(self, message)
    self.messages[#self.messages + 1] = message
    self.sent(self)
  end,
  close = function(self)
  end
}

Buffer = {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    o.leds = {}
    return o
  end,
  fade = function(self, value, direction) end,
  fill = function(self, color)
    for i = 1, self.numberOfLeds do
      self.leds[i] = color
    end
  end,
  set = function(self, index, color)
    self.leds[index] = color
  end,
  shift = function(self, value)
    for i = self.numberOfLeds - 1, 1, -1 do
      self.leds[i] = self.leds[i + 1]
    end
  end,
}

ws2812 = {
  pins = {},
  newBuffer = function(numberOfLeds, bytesPerLed)
    return Buffer:new({numberOfLeds = numberOfLeds, bytesPerLed = bytesPerLed})
  end,
  write = function(table)
    if (table.pin == nil or table.data == nil) then
      error("pin and data must be specified.")
    end
    ws2812.pins[table.pin] = table.data
  end
}
