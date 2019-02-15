parsePostData = function(httpRequest, postData)
  if (postData ~= nil and string.len(postData) > 0) then
    for k, v in pairs(sjson.decode(postData)) do
      httpRequest.parameters[k] = v
    end
 end
end

return {
  port = 80,
  resourceServlet,
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    o.services = o.services or {}
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  toAPIRequest = function(httpRequest)
    local apiRequest = {}
    if httpRequest.parameters then
      for k, v in pairs(httpRequest.parameters) do
        apiRequest[k] = v
      end
    end
    local path = httpRequest.path
    local customIndex = string.find(path, ":(.+)")
    if (customIndex) then
      apiRequest._action = string.sub(path, customIndex + 1)
      path = string.sub(path, 1, customIndex - 1)
    end
    path = string.sub(path, 2) .. "/0"
    for k, v in string.gmatch(path, "/(%w+)/(%w+)") do
      if (apiRequest._resource) then
        apiRequest[apiRequest._resource] = apiRequest.id
      end
      apiRequest._resource = k
      apiRequest.id = tonumber(v)
    end
    if (apiRequest.id == 0) then
      apiRequest.id = nil
    end
    if (apiRequest._action == nil) then
      if (httpRequest.method == "PUT" or httpRequest.method == "POST" and apiRequest.id == nil) then
        apiRequest._action = "create"
      elseif (httpRequest.method == "GET" and apiRequest.id) then
        apiRequest._action = "get"
      elseif (httpRequest.method == "GET") then
        apiRequest._action = "list"
      elseif (httpRequest.method == "PATCH" or httpRequest.method == "POST" and apiRequest.id) then
        apiRequest._action = "update"
      elseif (httpRequest.method == "DELETE") then
        apiRequest._action = "delete"
      end
    end
    return apiRequest
  end,
  doAPIRequest = function(self, apiRequest, response)
    local service = self.services[apiRequest._resource]
    if (service == nil) then
      print("Can not find service: "..toString(apiRequest._resource))
      return {_errorCode = 404, _message = "Not Found"}
    elseif (service[apiRequest._action] == nil) then
      return {_errorCode = 405, _message = "Method Not Allowed"}
    end
    return service[apiRequest._action](service, apiRequest, response)
  end,
  doHttpRequest = function(self, httpRequest, client)
    local result = self:doAPIRequest(self.toAPIRequest(httpRequest), client)
    if (type(result) == "table" and result._errorCode) then
      client:on("sent", function(c)
        c:close()
      end)
      client:send("HTTP/1.1 " .. result._errorCode .. " " .. result._message .. "\n")
    else
      local json = sjson.encode(result)
      local jsonSent = false
      function sendJson(c)
        if (jsonSent == false) then
          jsonSent = true
          c:send(json)
        else
          c:close()
        end
      end
      client:on("sent", sendJson)
      client:send("HTTP/1.1 200 OK\nContent-Type: application/json\nContent-Length: " .. string.len(json) .. "\n\n")
    end
  end,
  parseRequest = function(request)
    local parameters = {}
    local postData
    local _, _, method, path, vars, headers = string.find(request, "([A-Z]+) (.+)?(.+) HTTP(.+)")
    if (method == nil) then
      _, _, method, path, headers, postData = string.find(request, "([A-Z]+) (.+) HTTP(.+)\r\n\r\n(.*)")
    end
    if (method == nil) then
      _, _, method, path, headers = string.find(request, "([A-Z]+) (.+) HTTP(.+)")
    end
    if (vars ~= nil) then
      for var in string.gmatch(vars, "([^&]+)") do
        for k, v in string.gmatch(var, "(.+)=(.+)") do
          parameters[k] = sjson.decode(v)
        end
      end
    end
    local httpRequest = {
      method = method,
      path = path,
      parameters = parameters
    }
    parsePostData(httpRequest, postData)
    return httpRequest
  end,
  start = function(self)
    srv = net.createServer(net.TCP)
    srv:listen(self.port, function(conn)
      local httpRequest
      conn:on("receive", function(client, request)
        if (httpRequest == nil) then
          httpRequest = self.parseRequest(request)
          if (string.find(httpRequest.path, "/api/") == nil) then
            self.resourceServlet:doGet(httpRequest, client)
          elseif (httpRequest.method == "GET" or httpRequest.method == "DELETE" or next(httpRequest.parameters) ~= nil) then
            self:doHttpRequest(httpRequest, client)
          end
        else
          parsePostData(httpRequest, request)
          self:doHttpRequest(httpRequest, client)
        end
      end)
    end)
  end
}
