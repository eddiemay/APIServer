getContentType = function(fileName)
  local contentType
  fileName = string.lower(fileName)
  -- xlocal ext = string.sub(fileName, string.find(fileName, ".") + 1, -1)
  if (string.find(fileName, ".html")) then
    contentType = "text/html"
  elseif (string.find(fileName, ".css")) then
    contentType = "text/css"
  elseif (string.find(fileName, ".js")) then
    contentType = "application/javascript"
  else
    contentType = "image/" .. string.sub(fileName, -3, -1)
  end
  return contentType
end

return {
  doGet = function(self, request, response)
    local fileName = string.sub(request.path, 2, -1)
    if (string.len(fileName) == 0) then
      fileName = "index.html"
    end
    local fd = file.open(fileName, "r")
    -- If the file we are looking for does not exist and contains a slash (/) then
    -- remove try to load a file diectory from root without the diectory structure.
    if (fd == nil and fileName:find("/[^/]*$") ~= nil) then
      fd = file.open(fileName:sub(fileName:find("/[^/]*$") + 1), "r")
    end
    if (fd == nil) then
      response:on("sent", function(c)
        c:close()
      end)
      response:send("HTTP/1.1 404 Not Found\n")
      return
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
    response:send("HTTP/1.1 200 OK\nContent-Type: " .. getContentType(fileName) .. "\nCache-Control:public, max-age=31536000\n\n")
  end
}
