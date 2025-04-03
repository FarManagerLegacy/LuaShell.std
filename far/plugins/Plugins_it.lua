local function plugins_it ()
  local Plugins = far.GetPlugins()
  local i = 1
  return function()
    repeat
      local handle = Plugins[i]
      if not handle then return end
      i = i+1
      local pi = far.GetPluginInformation(handle)
      if pi then
        return pi,handle
      end
      mf.beep(); -- pi may be nul after plugin crash, e.g. NetBox
    until false
  end
end

if _cmdline then --testing
  print "Far iterator enumerating loaded plugins"
  print "Syntax: sh.plugins_it()"
  print ""
  local counter = 0
  for p in plugins_it() do
    print(("%-25s v%-21s %s"):
      format(p.GInfo.Title,
             sh.plugins.fmtVer(p.GInfo.Version),
             p.GInfo.Author))
    counter = counter+1
  end
  print ""
  print(("Total: %i plugins are found"):format(counter))
else
  return plugins_it
end
