local F = far.Flags
local actl,          GetWindowCount,       GetWindowInfo,       SetCurrentWindow
    = far.AdvControl,F.ACTL_GETWINDOWCOUNT,F.ACTL_GETWINDOWINFO,F.ACTL_SETCURRENTWINDOW

local function windowsRev_it (fn) --iterate over all screens in reverse order of w.Pos / ret: ret,w
  local i = actl(GetWindowCount)
  return function ()
    while true do
      if i==0 then return nil end
      local w = actl(GetWindowInfo,i)
      i = i-1
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
  print "Far windows iterator (reverse order)"
  print "Syntax: sh.windowsRev_it([filter_fn])"
  print ""
  for w in windowsRev_it() do
    print(w.Pos, w.TypeName, w.Id, w.Name)
  end
else
  return windowsRev_it
end
