MIME_TYPE = {
  css = "text/css",
  gif = "image/gif",
  html = "text/html",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  js = "application/javascript",
  lua = "application/lua",
  png = "image/png",
  svg = "image/svg+xml",
  txt = "text/plain",
}

getContentType = function(fileName)
  local ext = fileName:sub(fileName:find(".[^.]*$") + 1)
  local contentType = MIME_TYPE[ext]
  if (contentType == nil) then
    contentType = "image/" .. ext
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
