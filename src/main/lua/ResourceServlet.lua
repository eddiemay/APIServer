local MIME_TYPE = {
  css = "text/css",
  gif = "image/gif",
  html = "text/html",
  ico = "image/x-icon",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  js = "application/javascript",
  lua = "application/lua",
  png = "image/png",
  svg = "image/svg+xml",
  txt = "text/plain",
}

local getContentType = function(fileName)
  if (fileName:sub(-3) == ".gz") then
    fileName = fileName:sub(1, -4);
  end
  local ext = fileName:sub(fileName:find(".[^.]*$") + 1);
  local contentType = MIME_TYPE[ext];
  if (contentType == nil) then
    contentType = "image/" .. ext;
  end
  return contentType;
end

local getContentEncoding = function(fileName)
  if (fileName:sub(-3) == ".gz") then
    return "Content-Encoding: gzip\n";
  end
  return "";
end

local openFile = function(fileName)
  if (fileName:len() > 31) then
    fileName = fileName:sub(1, 15) .. "_" .. fileName:sub(-15);
  end
  return file.open(fileName, "r");
end

return {
  doGet = function(_, request, response)
    local fileName = string.sub(request.path, 2, -1);
    if (string.len(fileName) == 0) then
      fileName = "index.html";
    end
    local fd = openFile(fileName);
    -- If the file we are looking for does not exist and contains a slash (/) then
    -- remove the directory and try to the load the file from root.
    if (fd == nil and fileName:find("/[^/]*$") ~= nil) then
      fileName = fileName:sub(fileName:find("/[^/]*$") + 1);
      fd = openFile(fileName);
    end
    -- If we still have not found the file try gzip
    if (fd == nil) then
      fileName = fileName .. ".gz";
      fd = openFile(fileName);
    end
    if (fd == nil) then
      response:on("sent", function(c) c:close() end);
      response:send("HTTP/1.1 404 Not Found\n");
      return;
    end
    local function send(localSocket)
      local content = fd:read();
      if content then
        localSocket:send(content);
      else
        localSocket:close();
        fd:close();
      end
    end
    response:on("sent", send);
    response:send(
        "HTTP/1.1 200 OK\n" ..
            "Content-Type: " .. getContentType(fileName) .. "\n" ..
            getContentEncoding(fileName) ..
            "Cache-Control:public, max-age=31536000\n\n");
  end
}
