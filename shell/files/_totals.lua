local counter,fails,selected = ...
local msg = counter.." file(s) processed"
if selected~=0 then
  msg = msg..", "..selected.." (de)selected"
end
if fails~=0 then
  mf.beep()
  msg = msg..", "..fails.." failed"
end
print(msg)
sh.sharedUtils.SetUserScreen()

