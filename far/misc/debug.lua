if _cmdline and APanel.Visible and Area.Shell and _filename==win.JoinPath(APanel.Path, APanel.Current) then
  print "Toggle debug mode"
  print "When debug is on, scripts are not cached:"
  print "- in sh namespace"
  print "- in env (sh.autoload=true)"
  print "- in require 'sh' (used by macros), and existing cache is cleared"
  print ""
end

local O = sh._shared.options
O.debug = not O.debug
print("debug: "..(O.debug and "on" or "off"))
if O.debug then
  sh._shared.GlobalCache = {}
  local _sh = package.loaded.sh
  if _sh then
    require"table.clear"(_sh)
    _sh._shared = sh._shared
    _sh.print = sh.print
  end
end
