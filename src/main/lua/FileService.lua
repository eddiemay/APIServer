local writeFile = function(name, content)
  local fd = file.open(request.entity.name, "w")
  if (fd == nil) then
    return {_errorCode = 503, _message = "Internal server error"}
  end
  fd:write(request.entity.content)
  fd:close()
  return file.stat(name)
end

return {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    o.super = self
    self.__index = self
    return o
  end,
  create = function(self, request)
    if (request.entity == nil) then
      return {_errorCode = 402, _message = "Malformed request"}
    end
    return writeFile(request.entity.name, request.entity.content)
  end,
  get = function(self, request, response)
    local fileName = request.id
    local fd = file.open(fileName, "r")
    if (fd == nil) then
      return {_errorCode = 404, _message = "Not Found"}
    end
    local function send(localSocket)
      local content = fd:read()
      if content then
        localSocket:send(content)
      else
        localSocket:close()
        fd:close()
      end
    end
    response:on("sent", send)
    response:send("HTTP/1.1 200 OK\nContent-Type: " .. getContentType(fileName) .. "\r\n\r\n")
    return nil
  end,
  list = function(self, request)
    local results = {}
    local totalSize = 0
    local list = file.list();
    for name, size in pairs(list) do
      totalSize = totalSize + 1
      results[totalSize] = file.stat{name}
    end
    return {result = results, totalSize = totalSize}
  end,
  update = function(self, request)
    return writeFile(request.id, request.entity.content)
  end,
  delete = function(self, request)
    file.remove(request.id)
    return {}
  end
}