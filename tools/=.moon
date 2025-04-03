if not ...
  print "Usage: = <expression>"
  return
mt = setmetatable {},{ __index:(t,k)-> _G[k] or _G.math[k]}
f = assert require"moonscript".loadstring _cmdline
mf.print '= '..(setfenv f,mt)!

-- or as oneliner console alias:
-- ==moon:print '= '..((f)->(setfenv f,setmetatable {},{__index:(t,k)->_G[k] or _G.math[k]})!) -> $*
