function assertEquals(expected, actual, message)
  if (expected ~= actual) then
    error(message or "Assert failure.\nExpected: " .. toString(expected) .. "\n  Actual: " .. toString(actual))
  end
end

function assertStartsWith(expected, actual, message)
  if (string.find(actual, expected) ~= 1) then
    error(message or "Assert failure.\nExpected: "..toString(actual).." to start with: "..toString(expected))
  end
end

function test(description, testFunc, ignore)
  if (not ignore) then
    testFunc()
  end
end

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
    if self.needsReset then
      self.curLine = 0
      self.lines = {}
      self.needsReset = false
    end
    self.curLine = self.curLine + 1
    self.lines[self.curLine] = line
  end,
  readline = function(self)
    if (self.curLine < #self.lines) then
      self.curLine = self.curLine + 1
      return self.lines[self.curLine]
    end
    return nil
  end,
  close = function(self)
  end
}

file = file or {
  files = {},
  open = function(name, purpose)
    file.files[name] = file.files[name] or FakeFile:new { fileName = name, purpose = purpose or "r", lines = {} }
    local fd = file.files[name]
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
  end
}

sjson = sjson or require "json"

gpio = gpio or {
  OUTPUT = 1,
  OPENDRAIN = 2,
  INPUT = 3,
  INT = 4,
  HIGH = 1,
  LOW = 0,
  pins = {},
  mode = function(pin, mode)
    gpio.pins[pin] = gpio.pins[pin] or {}
    gpio.pins[pin].mode = mode
  end,
  write = function(pin, value)
    gpio.pins[pin].value = value
  end,
  read = function(pin)
    return gpio.pins[pin].value
  end,
  trig = function(pin, Function)
    gpio.pins[pin].trig = Function
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
  start = function() end,
  register = function(self, interval_ms, mode, func) end,
  unregister = function(self) end,
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
  init = function() end,
  newBuffer = function(numberOfLeds, bytesPerLed)
    return Buffer:new({numberOfLeds = numberOfLeds, bytesPerLed = bytesPerLed})
  end,
  write = function(buffer) end
}
