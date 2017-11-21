local MATCHERS = {
  ['<'] = function(value, matchValue) return value < matchValue end,
  ['<='] = function(value, matchValue) return value <= matchValue end,
  ['='] = function(value, matchValue) return value == matchValue end,
  ['?'] = function(value, matchValue) return value == matchValue end,
  ['>='] = function(value, matchValue) return value >= matchValue end,
  ['>'] = function(value, matchValue) return value > matchValue end,
  ['!='] = function(value, matchValue) return value ~= matchValue end,
}

return {
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    o.tables = o.tables or {}
    o.sequences = o.sequences or {}
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  seqNextVal = function(self, table)
    self.sequences[table] = (self.sequences[table] or 999) + 1
    return self.sequences[table]
  end,
  create = function(self, table, item)
    item.id = item.id or self:seqNextVal(table)
    self.tables[table] = self.tables[table] or {}
    self.tables[table][item.id] = item
    return item
  end,
  get = function(self, table, id)
    if self.tables[table] then
      return self.tables[table][id]
    end
    return nil
  end,
  list = function(self, table, query)
    local queryResult = { result = {}, totalSize = 0 }
    local items = self.tables[table]
    if items then
      local limit = query.limit or 0
      local offset = query.offset or 0
      local filters = query.filter or {}
      local orderBy = query.orderBy or {} -- TODO(eddiemay) Figure out how to do order by.
      local added = 0
      local matchedAll = true
      for k, item in pairs(items) do
        matchedAll = true
        for f = 1, #filters do
          local filter = filters[f]
          if not (MATCHERS[filter.operator or '='](item[filter.column], filter.value)) then
            matchedAll = false
          end
        end
        if (matchedAll) then
          queryResult.totalSize = queryResult.totalSize + 1
          if (queryResult.totalSize > offset and (limit == 0 or added < limit)) then
            added = added + 1
            queryResult.result[added] = item
          end
        end
      end
    end
    return queryResult
  end,
  update = function(self, table, id, updater)
    local item = self.tables[table][id]
    if (item == nil) then
      return nil
    end
    local updated = updater(item)
    self.tables[table][id] = updated
    return updated
  end,
  delete = function(self, table, id)
    self.tables[table][id] = nil
    return ""
  end
}
