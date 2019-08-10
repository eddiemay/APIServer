HTTP_STATUS_CODE = {
  OK = 200,
  MOVED_PERMANENTLY = 301,
  NOT_MODIFIED = 304,
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  UNAUTENTICATED = 401,
  PAYMENT_REQUIRED = 402,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  METHOD_NOT_ALLOWED = 405,
  INTERNAL_SERVER_ERROR = 500,
  NOT_IMPLEMENTED = 501,
  SERVICE_UNAVAILABLE = 503
}

HTTP_ERROR = {
  OK = {_errorCode = 200, _message = "OK"},
  MOVED_PERMANENTLY = {_errorCode = 301, _message = "Moved Permanently"},
  NOT_MODIFIED = {_errorCode = 304, _message = "Not Modified"},
  BAD_REQUEST = {_errorCode = 400, _message = "Bad Request"},
  UNAUTHORIZED = {_errorCode = 401, _message = "Unauthorized"},
  UNAUTENTICATED = {_errorCode = 401, _message = "Unauthenticated"},
  PAYMENT_REQUIRED = {_errorCode = 402, _message = "Payment Required"},
  FORBIDDEN = {_errorCode = 403, _message = "Forbidden"},
  NOT_FOUND = {_errorCode = 404, _message = "Not Found"},
  METHOD_NOT_ALLOWED = {_errorCode = 405, _message = "Method Not Allowed"},
  INTERNAL_SERVER_ERROR = {_errorCode = 500, _message = "Internal Server Error"},
  NOT_IMPLEMENTED = {_errorCode = 501, _message = "Not Implemented"},
  SERVICE_UNAVAILABLE = {_errorCode = 503, _message = "Service Unavailable"}
}

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
  xml = "text/xml"
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