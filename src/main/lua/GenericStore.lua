return {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    if (o.name == nil) then
      error("Name is required")
    end
    if (o.dao == nil) then
      error("dao is required")
    end
    o.super = self
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  create = function(self, item)
    return self.dao:create(self.name, item)
  end,
  get = function(self, id)
    return self.dao:get(self.name, id)
  end,
  list = function(self, query)
    return self.dao:list(self.name, query)
  end,
  update = function(self, id, updater)
    return self.dao:update(self.name, id, updater)
  end,
  delete = function(self, id)
    return self.dao:delete(self.name, id)
  end
}
