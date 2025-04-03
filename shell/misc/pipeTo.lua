-- Requires piper module https://forum.farmanager.com/viewtopic.php?t=13424
-- otherwise use pipeTo.lua.simple instead
local function pipeto (cmd,input)
  local prc = require"piper"("cmd.exe /c"..cmd, {input=input})
  if prc then return prc.all, prc.ExitCode end
end

if _cmdline=="" then
  print "Executes specified command, putting specified text to it's input stream,"
  print "and returns it's output/err"
  print "Syntax: out = sh.pipeto(cmd,input)"
elseif _cmdline then
  print((pipeto(...)))
else
  return pipeto
end
