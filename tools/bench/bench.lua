local N = 1

local function bench (fn,n,...)
  collectgarbage()
  collectgarbage()
  local start = far.FarClock()

  for i=1,n do fn(...) end

  return (far.FarClock()-start)/1000000
end

if not _cmdline then -- export
  return bench
elseif _cmdline=="" then
  print "Usage: bench [n] name|code [args]"
  return
end

local i, n, code = 3, ...
n = code and tonumber(n,10)
if not n then
  i, n, code = 2, N, ...
end

local _,fn = pcall(code.eval, code)
fn = type(fn)=="function" and fn or sh(code)

far.Show(n, bench(fn,n,select(i,...)))

-- e.g.:
-- bench.lua sleep.lua 100  -- script + args
-- bench.lua mf.sleep 200   -- code (fn)
-- bench.lua 2 mf.sleep 200 -- *n
