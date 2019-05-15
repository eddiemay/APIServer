local ReadWriteFile = {
  fileName,
  inFile,
  outFile,
  new = function(self, o)
    o = o or {};   -- create object if user does not provide one
    setmetatable(o, self);
    self.__index = self;
    return o;
  end,
  writeline = function(self, line)
    if (self.outFile == nil) then
      self.outFile = file.open("." .. self.fileName, "w");
    end
    self.outFile:writeline(line);
  end,
  readline = function(self)
    return self.inFile:readline();
  end,
  read = function(self)
    return self.inFile:readline();
  end,
  close = function(self)
    self.inFile:close();
    file.remove(self.fileName);
    if (self.outFile) then
      self.outFile:close();
      file.rename("." .. self.fileName, self.fileName);
    end
  end
}

local function openFile(resource, purpose)
  local fileName = "data/" .. resource .. ".json";
  if (purpose ~= "rw") then
    return file.open(fileName, purpose);
  end
  local inFile = file.open(fileName, "r");
  if (inFile == nil) then
    return nil;
  end
  return ReadWriteFile:new{inFile = inFile, fileName = fileName};
end

SequenceProvider = {
  sequenceGenerator = nil,
  fileName = "data/sequences.lua",
  get = function()
    if (SequenceProvider.sequenceGenerator == nil) then
      local sequenceGenerator = {
        nextValue = function(self, resource)
          self.sequences[resource] = (self.sequences[resource] or 999) + 1;
          local fd = file.open(SequenceProvider.fileName, "w");
          fd:writeline(toString(self.sequences));
          fd:close();
          return self.sequences[resource];
        end
      }
      sequenceGenerator.sequences = {};
      local fd = file.open(SequenceProvider.fileName, "r");
      if (fd) then
        for k, v in string.gmatch(fd:readline() or "", "(%w+) = (%d+)") do
          sequenceGenerator.sequences[k] = v;
        end
      end
      SequenceProvider.sequenceGenerator = sequenceGenerator;
    end
    return SequenceProvider.sequenceGenerator;
  end,
}

return {
  sequenceGenerator = nil,

  new = function(self, o)
    o = o or {}; -- create object if user does not provide one
    o.sequenceGenerator = o.sequenceGenerator or SequenceProvider:get();
    setmetatable(o, self);
    self.__index = self;
    return o;
  end,

  create = function(self, resource, item)
    if (item.id and self:update(resource, item.id, function() return item end)) then
      return item;
    end
    item.id = item.id or self.sequenceGenerator:nextValue(resource);
    local fd = openFile(resource, "a");
    fd:writeline(sjson.encode(item));
    fd:close();
    return item;
  end,

  get = function(_, resource, id)
    local fd = openFile(resource, "r");
    if (fd == nil) then
      return nil;
    end
    local line = fd:readline();
    while line do
      item = sjson.decode(line);
      if (item.id == id) then
        fd:close();
        return item;
      end
      line = fd:readline();
    end
    fd:close();
    return nil;
  end,

  list = function(_, resource, query)
    local results = {};
    local totalSize = 0;
    local fd = openFile(resource, "r");
    if (fd == nil) then
      return {results = results, totalSize = totalSize};
    end
    query = query or {};
    local limit = query.limit or 0;
    local offset = query.offset or 0;
    local filters = query.filter or {};
    --local orderBy = query.orderBy or {} -- TODO(eddiemay) Figure out how to do order by.
    local matchedAll;
    local line = fd:readline();
    while line do
      local item = sjson.decode(line);
      matchedAll = true;
      for f = 1, #filters do
        local filter = filters[f];
        if not (MATCHERS[filter.operator or '='](item[filter.column], filter.value)) then
          matchedAll = false;
        end
      end
      if matchedAll then
        totalSize = totalSize + 1;
        if (totalSize > offset and (limit == 0 or #results < limit)) then
          results[#results + 1] = item;
        end
      end
      line = fd:readline();
    end
    fd:close();
    return {results = results, totalSize = totalSize};
  end,

  update = function(_, resource, id, updater)
    local updated;
    local fd = openFile(resource, "rw");
    if (fd == nil) then
      return nil;
    end
    local line = fd:readline();
    while line do
      local item = sjson.decode(line);
      if (item.id == id) then
        updated = updater(item);
        item = updated;
      end
      fd:writeline(sjson.encode(item));
      line = fd:readline();
    end
    fd:close();
    return updated;
  end,

  delete = function(_, resource, id)
    local fd = openFile(resource, "rw");
    if (fd == nil) then
      return {};
    end
    local line = fd:readline();
    while line do
      local item = sjson.decode(line);
      if (item.id ~= id) then
        fd:writeline(sjson.encode(item));
      end
      line = fd:readline();
    end
    fd:close();
    return {};
  end
}
