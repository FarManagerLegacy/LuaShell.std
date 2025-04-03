function path () --luacheck: ignore path
  return far.ConvertPath(getfenv(2).FileName, "CPM_NATIVE")
end

local t = win.GetSystemTime() --now
t.wHour = nil
t.wMinute = nil
t.wSecond = nil
t.wMilliseconds = nil
local from = win.SystemTimeToFileTime(t)

function today (time)
  return time>from
end