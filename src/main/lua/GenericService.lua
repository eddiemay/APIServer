return {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    o.super = self
    if (o.store == nil) then
      error("store is nil")
    end
    self.__index = self
    return o
  end,
  create = function(self, request)
    if (request.entity == nil) then
      error("entity is nil")
    end
    return self.store:create(request.entity)
  end,
  get = function(self, request)
    local entity = self.store:get(request.id)
    if (entity == nil) then
      return { _errorCode = 404, _message = "Not Found" }
    end
    return entity
  end,
  list = function(self, request)
    return self.store:list{
      filter = request.filter,
      limit = request.pageSize,
      offset = request.pageToken,
      orderBy = request.orderBy}
  end,
  update = function(self, request)
    local item = self.store:update(request.id, function(current)
      local entity = request.entity
      local updated = copy(current)
      local updateMask = request.updateMask
      for i, property in pairs(updateMask) do
        updated[property] = entity[property]
      end
      return updated
    end)
    if (item == nil) then
      return { _errorCode = 404, _message = "Not Found" }
    end
    return item
  end,
  delete = function(self, request)
    self.store:delete(request.id)
    return {}
  end
}
