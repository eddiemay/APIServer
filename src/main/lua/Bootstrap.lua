-- Map loadstring(str) to load(str) if not defined.
loadstring = loadstring or load

function copy(src)
  if (type(src) == "table") then
    local dst = {}
    for k, v in pairs(src) do
      dst[k] = copy(v)
    end
    return dst
  end
  return src
end
function toString(obj)
  if (type(obj) == "table" and #obj > 0) then
    --Array
    local ret = ""
    for i = 1, #obj do
      if (string.len(ret) > 0) then
        ret = ret .. ", "
      end
      ret = ret .. toString(obj[i])
    end
    return "{" .. ret .. "}"
  elseif (type(obj) == "table") then
    local ret = ""
    for k, v in pairs(obj) do
      if (string.len(ret) > 0) then
        ret = ret .. ", "
      end
      ret = ret .. k .. " = " .. toString(v)
    end
    return "{" .. ret .. "}"
  elseif (type(obj) == "string") then
    return "\"" .. obj .. "\""
  end
  return tostring(obj)
end
