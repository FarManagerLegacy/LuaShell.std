assert(_cmdline, "meant to be executed directly")
local F = far.Flags
local path = ...
if not path then
  path = far.GetCurrentDirectory()
end
local plugins = sh.PluginsDLLs_it(path)
local Plugins, Loaded = {}, {}
for item in plugins do
  local handle = far.FindPlugin(F.PFM_MODULENAME, item.ModuleName)
  if handle then
    item = far.GetPluginInformation(handle)
    item.handle = handle
    Loaded[#Loaded+1] = item
  else
    Plugins[#Plugins+1] = item
  end
end

local exact
if #Plugins==0 then
  if _cmdline=="" then
    print "Load plugins located in specified path (recursively)."
    print "If there are several plugins found then list is diplayed."
    print "Usage: load <path> [list|batch]"
    print '- "list" show list even when exactly one plugin found'
    print '- "batch" enforces mass loading (no list displayed)'
    print "Note: if <path> is not specified then current directory is assumed."
    print ""
  end
  print("No plugins found", ("[path: %s]"):format(path))
  return
elseif #Plugins==1 then
  exact = 1
end

local function loadBatch ()
  local loaded_counter = 0
  for _,p in ipairs(Plugins) do
    if not p.handle then
      local status = ""
      local handle = far.LoadPlugin(F.PLT_PATH, p.ModuleName)
      if handle and far.GetPluginInformation(handle) then
        loaded_counter = loaded_counter+1
      else
        status = "Failed!"
      end
      print(p.GInfo.Title, status)
    end
  end
  print(("Total: %i plugins loaded"):format(loaded_counter),
        ("[path: %s]"):format(path))
end

local nargs = select('#', ...)
local last = nargs>0 and select(nargs, ...)
if (exact and last~="list") or last=="batch" then
  loadBatch()
else
  sh.plugins.List({
    Title="Load plugin:",
    Id=win.Uuid"0B026088-C876-4ED2-BE9F-06A0D6079E15",
    markLoaded="✔+",
    markUnloaded="✗x",
    batchFn=loadBatch,
  }, Plugins, Loaded)
end
