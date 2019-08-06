parsePostData = function(httpRequest, postData)
  if (postData == nil or string.len(postData) == 0) then
    return;
  end
  if (httpRequest.postData) then
    httpRequest.postData = httpRequest.postData .. postData;
  else
    httpRequest.postData = postData;
  end
  if (postData:sub(1, 2) == "{\"") then
    for k, v in pairs(sjson.decode(postData)) do
      httpRequest.parameters[k] = v;
    end
  end
end

local decode = function(value)
  local number = tonumber(value);
  if (number == nil or (number == 0 and value ~= "0")) then
    return value;
  end
  return number;
end

local SERVLET_ACTIONS = {
 GET = "doGet", POST = "doPost", PUT = "doPut", PATCH = "doPatch", DELETE = "doDelete"
};

return {
  port = 80,
  resourceServlet,
  new = function(self, o)
    o = o or {};   -- create object if user does not provide one
    o.services = o.services or {};
    o.servlets = o.servlets or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
  end,

  toAPIRequest = function(httpRequest)
    local apiRequest = {};
    if httpRequest.parameters then
      for k, v in pairs(httpRequest.parameters) do
        apiRequest[k] = v;
      end
    end
    local path = httpRequest.path;
    local customIndex = string.find(path, ":(.+)");
    if (customIndex) then
      apiRequest._action = string.sub(path, customIndex + 1);
      path = string.sub(path, 1, customIndex - 1);
    end
    path = string.sub(path, 2) .. "/0";
    for k, v in string.gmatch(path, "/(%w+)/(%w+)") do
      if (apiRequest._resource) then
        apiRequest[apiRequest._resource] = apiRequest.id;
      end
      apiRequest._resource = k;
      apiRequest.id = tonumber(v);
    end
    if (apiRequest.id == 0) then
      apiRequest.id = nil;
    end
    if (apiRequest._action == nil) then
      if (httpRequest.method == "PUT" or httpRequest.method == "POST" and apiRequest.id == nil) then
        apiRequest._action = "create";
      elseif (httpRequest.method == "GET" and apiRequest.id) then
        apiRequest._action = "get";
      elseif (httpRequest.method == "GET") then
        apiRequest._action = "list";
      elseif (httpRequest.method == "PATCH" or httpRequest.method == "POST" and apiRequest.id) then
        apiRequest._action = "update";
      elseif (httpRequest.method == "DELETE") then
        apiRequest._action = "delete";
      end
    end
    return apiRequest
  end,

  doAPIRequest = function(self, apiRequest, response)
    local service = self.services[apiRequest._resource];
    if (service == nil) then
      print("Can not find service: " .. toString(apiRequest._resource));
      return {_errorCode = 404, _message = "Not Found"};
    elseif (service[apiRequest._action] == nil) then
      return {_errorCode = 405, _message = "Method Not Allowed"};
    end
    return service[apiRequest._action](service, apiRequest, response);
  end,

  doServletRequest = function(self, httpRequest, response)
    local _, _, servletName = string.find(httpRequest.path, "/servlet/(%w+)");
    local servlet = self.servlets[servletName];
    local action = SERVLET_ACTIONS[httpRequest.method];
    if (servlet == nil) then
      print("Can not find servlet: " .. toString(servletName));
      return {_errorCode = 404, _message = "Not Found"};
    elseif (servlet[action] == nil) then
      return {_errorCode = 405, _message = "Method Not Allowed"};
    end
    return servlet[action](servlet, httpRequest, response);
  end,

  doHttpRequest = function(self, httpRequest, response)
    local result;
    if (string.find(httpRequest.path, "/api/") ~= nil) then
      result = self:doAPIRequest(self.toAPIRequest(httpRequest), response);
    elseif (string.find(httpRequest.path, "/servlet/") ~= nil) then
      result = self:doServletRequest(httpRequest, response);
    end

    -- If the result will be self served by the service then we do not process.
    if (type(result) ~= "table" or result._selfServed ~= true) then
      self.sendResponse(result, response);
    end
  end,

  sendResponse = function(result, client)
    if (type(result) == "table" and result._errorCode) then
      client:on("sent", function(c)
        c:close();
      end)
      client:send("HTTP/1.1 " .. result._errorCode .. " " .. result._message .. "\n");
    else
      local json = sjson.encode(result);
      local jsonSent = false;
      function sendJson(c)
        if (jsonSent == false) then
          jsonSent = true;
          c:send(json);
        else
          c:close();
        end
      end
      client:on("sent", sendJson);
      client:send("HTTP/1.1 200 OK\nContent-Type: application/json\nContent-Length: " .. json:len() .. "\n\n");
    end
  end,

  parseRequest = function(request)
    local parameters = {};
    local postData;
    local _, _, method, path, vars, headers = string.find(request, "^([A-Za-z]+) (.+)?(.+) HTTP(.+)");
    if (method == nil) then
      _, _, method, path, headers, postData = string.find(request, "^([A-Za-z]+) (.+) HTTP(.+)\r\n\r\n(.*)");
    end
    if (method == nil) then
      _, _, method, path, headers = string.find(request, "^([A-Za-z]+) (.+) HTTP(.+)");
    end
    if (vars ~= nil) then
      for var in string.gmatch(vars, "([^&]+)") do
        for k, v in string.gmatch(var, "(.+)=(.+)") do
          parameters[k] = decode(v);
        end
      end
    end
    local httpRequest = {
      method = string.upper(method),
      path = path,
      headers = headers,
      parameters = parameters
    }
    parsePostData(httpRequest, postData);
    return httpRequest;
  end,

  start = function(self)
    print("Starting server on port: " .. self.port);
    srv = net.createServer(net.TCP);
    srv:listen(self.port, function(conn)
      local httpRequest;
      conn:on("receive", function(client, request)
        if (httpRequest == nil) then
          httpRequest = self.parseRequest(request);
          if (string.find(httpRequest.path, "/api/") == nil and string.find(httpRequest.path, "/servlet/") == nil) then
            self.resourceServlet:doGet(httpRequest, client);
          elseif (httpRequest.method == "GET" or httpRequest.method == "DELETE" or httpRequest.postData ~= nil) then
            self:doHttpRequest(httpRequest, client);
          end
        else
          parsePostData(httpRequest, request);
          self:doHttpRequest(httpRequest, client);
        end
      end)
    end)
  end
}
