MIME_TYPE = {
  css = "text/css",
  gif = "image/gif",
  html = "text/html",
  ico = "image/x-icon",
  jpeg = "image/jpeg",
  jpg = "image/jpeg",
  js = "application/javascript",
  lua = "application/lua",
  png = "image/png",
  svg = "image/svg+xml",
  txt = "text/plain",
}

getContentType = function(fileName)
  if (fileName:sub(-3) == ".gz") then
    fileName = fileName:sub(1, -4);
  end
  local ext = fileName:sub(fileName:find(".[^.]*$") + 1);
  local contentType = MIME_TYPE[ext];
  if (contentType == nil) then
    contentType = "image/" .. ext;
  end
  return contentType;
end;

getContentEncoding = function(fileName)
  if (fileName:sub(-3) == ".gz") then
    return "Content-Encoding: gzip\n";
  end
  return "";
end;