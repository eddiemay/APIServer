local getFileName = function(request)
  local _, _, _, fileName = string.find(request.path, "/servlet/(%w+)/(.+)");
  return fileName;
end

local list = function()
  local results = {};
  local totalSize = 0;
  local list = file.list();
  for name, size in pairs(list) do
    totalSize = totalSize + 1;
    results[totalSize] = {name = name, size = size};
  end
  return {results = results, totalSize = totalSize};
end

FileServlet = FileServlet or {
  new = function(self, o)
    o = o or {}; -- create object if user does not provide one
    setmetatable(o, self);
    o.super = self;
    self.__index = self;
    return o;
  end,

  doGet = function(_, request, response)
    local fileName = getFileName(request);
    if (fileName == nil) then
      return list();
    end
    return FileServlet.outputFile(fileName, response);
  end,

  doPost = function(_, request, response)
    return FileServlet.readInFile(getFileName(request), request, response);
  end,

  doDelete = function(_, request)
    local fileName = getFileName(request);
    file.remove(fileName);
    return {};
  end,

  outputFile = function(fileName, response)
    local fd = file.open(fileName, "r");
    if (fd == nil) then
      return HTTP_ERROR.NOT_FOUND;
    end

    response:on("sent", function(localSocket)
      local content = fd:read();
      if content then
        localSocket:send(content);
      else
        localSocket:close();
        fd:close();
      end
    end);

    response:send("HTTP/1.1 200 OK\nContent-Type: " .. getContentType(fileName) .. "\r\n\r\n");
    return {_selfServed = true};
  end,

  readInFile = function(fileName, request, response)
    local _, _, contentLength = string.find(request.headers, "Length: (%d+)");
    contentLength = tonumber(contentLength);
    local fd = file.open(fileName, "w");
    if (fd == nil) then
      return HTTP_ERROR.INTERNAL_SERVER_ERROR;
    end

    local fileSize = 0;
    local writeData = function(postData)
      fd:write(postData);
      fileSize = fileSize + string.len(postData);
      if (fileSize >= contentLength) then
        response:send("HTTP/1.1 200 OK\n\n");
        fd:close();
      end
    end

    response:on("receive", function(_, postData) writeData(postData) end);
    response:on("sent", function(localSocket) localSocket:close(); end);

    writeData(request.postData);

    return {_selfServed = true};
  end
}

return FileServlet;