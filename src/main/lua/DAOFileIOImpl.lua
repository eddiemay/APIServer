local MATCHERS = {
  ['<'] = function(value, matchValue) return value < matchValue end,
  ['<='] = function(value, matchValue) return value <= matchValue end,
  ['='] = function(value, matchValue) return value == matchValue end,
  ['?'] = function(value, matchValue) return value == matchValue end,
  ['>='] = function(value, matchValue) return value >= matchValue end,
  ['>'] = function(value, matchValue) return value > matchValue end,
  ['!='] = function(value, matchValue) return value ~= matchValue end,
}

local function getPath(tableName)
  return "data/" .. tableName .. ".json"
end

local function getTempPath(tableName)
  return "data/." .. tableName .. ".json"
end

SequenceProvider = {
  sequenceGenerator = nil,
  fileName = "sequences.lua",
  get = function()
    if (SequenceProvider.sequenceGenerator == nil) then
      local sequenceGenerator = {
        nextValue = function(self, table)
          self.sequences[table] = (self.sequences[table] or 999) + 1
          local fd = file.open("sequences.lua", "w")
          fd:writeline(toString(self.sequences))
          fd:close()
          return self.sequences[table]
        end
      }
      sequenceGenerator.sequences = {}
      local fd = file.open("sequences.lua", "r")
      if (fd) then
        for k, v in string.gmatch(fd:readline() or "", "(%w+) = (%d+)") do
          sequenceGenerator.sequences[k] = v
        end
      end
      SequenceProvider.sequenceGenerator = sequenceGenerator
    end
    return SequenceProvider.sequenceGenerator
  end,
}

return {
  sequenceGenerator = nil,
  new = function(self, o)
    o = o or {}   -- create object if user does not provide one
    o.sequenceGenerator = o.sequenceGenerator or SequenceProvider:get()
    setmetatable(o, self)
    self.__index = self
    return o
  end,
  create = function(self, table, item)
    if (item.id) then
      if (self:update(table, item.id, function(current) return item end)) then
        return item
      end
    end
    item.id = item.id or self.sequenceGenerator:nextValue(table)
    local fd = file.open(getPath(table), "a")
    fd:writeline(sjson.encode(item))
    fd:close()
    return item
  end,
  get = function(self, table, id)
    local fd = file.open(getPath(table), "r")
    if fd then
      local line = fd:readline()
      while line do
        item = sjson.decode(line)
        if (item.id == id) then
          fd:close()
          return item
        end
        line = fd:readline()
      end
      fd:close()
    end
    return nil
  end,
  list = function(self, table, query)
    local results = {}
    local totalSize = 0
    local fd = file.open(getPath(table), "r")
    if fd then
      query = query or {}
      local limit = query.limit or 0
      local offset = query.offset or 0
      local filters = query.filter or {}
      --local orderBy = query.orderBy or {} -- TODO(eddiemay) Figure out how to do order by.
      local matchedAll
      local line = fd:readline()
      while line do
        local item = sjson.decode(line)
        matchedAll = true
        for f = 1, #filters do
          local filter = filters[f]
          if not (MATCHERS[filter.operator or '='](item[filter.column], filter.value)) then
            matchedAll = false
          end
        end
        if (matchedAll) then
          totalSize = totalSize + 1
          if (totalSize > offset and (limit == 0 or #results < limit)) then
            results[#results + 1] = item
          end
        end
        line = fd:readline()
      end
      fd:close()
    end
    return {result = results, totalSize = totalSize}
  end,
  update = function(self, table, id, updater)
    local updated
    local fileName = getPath(table)
    local fileIn = file.open(fileName, "r")
    if (fileIn == nil) then
      return updated
    end
    local tmpFileName = getTempPath(table)
    local fileOut = file.open(tmpFileName, "w")
    local line = fileIn:readline()
    while line do
      local item = sjson.decode(line)
      if (item.id == id) then
        updated = updater(item)
        item = updated
        fileOut:writeline(sjson.encode(item))
      else
        fileOut:writeline(line)
      end
      line = fileIn:readline()
    end
    fileIn:close()
    fileOut:close()
    file.remove(fileName)
    file.rename(tmpFileName, fileName)
    return updated
  end,
  delete = function(self, table, id)
    local fd = file.open(getPath(table), "r")
    if fd then
      local items = {}
      local line = fd:readline()
      while line do
        local item = sjson.decode(line)
        if (item.id ~= id) then
          items[#items + 1] = item
        end
        line = fd:readline()
      end
      fd:close()
      fd = file.open(getPath(table), "w")
      for x = 1, #items do
        fd:writeline(sjson.encode(items[x]))
      end
      fd:close()
    end
    return {}
  end
}
