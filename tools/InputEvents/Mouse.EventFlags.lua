--https://api.farmanager.com/ru/macro/macrocmd/prop_func/general.html#MsEventFlags
--https://farmanagerlegacy.github.io/macro-api/mouse.html
assert(_cmdline, "meant to be executed directly")
print "Inspect Mouse.EventFlags property"
print "Press key or Mouse button/wheel ('Esc' to quit)"
local MsEventFlags = {
  [1] = "MOUSE_MOVED",
  [2] = "DOUBLE_CLICK",
  [4] = "MOUSE_WHEELED",
  [8] = "MOUSE_HWHEELED",
}

local last = 0
repeat
  local key = mf.waitkey(100)
  local ms = Mouse.EventFlags
  if key~="" or last~=ms then
    last = ms
    print(("%-20s│ %s"):format(key, MsEventFlags[ms] or ms==0 and "-" or ms))
  end
until key=="Esc"
