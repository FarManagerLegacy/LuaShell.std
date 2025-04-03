if _cmdline=="" then
  print "Usage: goto script_name"
elseif _cmdline then
  local filename = sh.where(...)
  local dir,name = filename:match("^(.+\\)(.-)$")
  panel.SetPanelDirectory(nil,1,dir) --see mbrowser.lua/LocateFile
  Panel.SetPath(0,dir,name)
else
  error "meant to be executed directly"
end
