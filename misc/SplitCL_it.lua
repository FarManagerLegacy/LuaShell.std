-- adapted from original source by Shmuel
-- https://forum.farmanager.com/viewtopic.php?p=167731#p167731
local splitCL_it do
  local pattern = [=[
    (" ( (?: \\" | [^"] )* ) "?) |
    ( (?: \\" | [^"\s] )+ ) |
    \s+
  ]=]
  splitCL_it = function (str)
    local outside = true
    local iter = regex.gmatch(str,pattern,"x")
    return function ()
      local arg, raw
      repeat
        local origin,a,b = iter()
        local match = a or b
        if match then
          origin = origin or b
          match = match:gsub("\\\"", "\"")
          if outside then
            outside = false
            arg = match
            raw = origin
          else
            arg = arg..match
            raw = raw..origin
          end
        else
          outside = true
          return arg, raw
        end
      until false
    end
  end
end

if _cmdline=="" then
  print "Iterator splitting commandline into separate arguments."
  print "Returns both unquoted and original arguments substrings."
  print "Example:"
  print("splitCL_it([["..[[1 "2 a" \"3" "b\"]].."]])","=>")
  sh.each(splitCL_it([[1 "2 a" \"3" "b\"]]),print)
elseif _cmdline then
  sh.each(splitCL_it(_cmdline),print)
else
  return splitCL_it
end
