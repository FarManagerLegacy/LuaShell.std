local F = far.Flags
local actl,          GetWindowCount,       GetWindowInfo,       SetCurrentWindow
    = far.AdvControl,F.ACTL_GETWINDOWCOUNT,F.ACTL_GETWINDOWINFO,F.ACTL_SETCURRENTWINDOW

local function windows_it (fn) --iterate over all screens in order of w.Pos / ret: ret,w
  local i = 1
  return function ()
    while true do
      local w = actl(GetWindowInfo,i)
      if w==nil then return nil end
      i = i+1
      if fn then
        local ret = fn(w)
        if ret then return ret,w end
      else
        return w
      end
    end
  end
end

if _cmdline then --testing
  print "Far windows iterator"
  print "Syntax: sh.windows_it([filter_fn])"
  print ""
  for w in windows_it() do
    print(w.Pos, w.TypeName, w.Id, w.Name)
  end
else
  return windows_it
end
