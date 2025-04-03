assert(_cmdline, "meant to be executed directly")
local arg,x = ...
if arg=="x" then
  x,arg = ...
end
if not arg then
  arg = far.GetCurrentDirectory()
elseif arg=="*" then
  arg = nil
end

local plugins,source = sh.findPlug_it(arg,x)
local Plugins = {}
for item,handle,passed in plugins do
  local idx = #Plugins+1
  Plugins[idx] = item
  item.selected = passed=="exact" and idx
  item.handle = handle
end

local exact
if #Plugins==0 then
  if _cmdline=="" then
    print "Unloads plugins specified by name, path, guid or module."
    print "If there are several matches (and none of them is exact) then list is displayed."
    print "Usage: unload [<str>] [x] [batch]"
    print '- "x" inverts matching'
    print '- "batch" enforces mass unloading (no list displayed)'
    print "Notes:"
    print "  If <arg> is not specified then current path assumed."
    print "  Use * to show all plugins"
    print ""
  end
  local tmpl = arg and "[%s: %s]" or "[%s]"
  print("No (loaded) plugins found", tmpl:format(source, arg))
  return
elseif #Plugins==1 then
  exact = arg and 1
end

local selfId = far.PluginStartupInfo().PluginGuid
local function unloadBatch (cacheFn)
  local unloaded_counter = 0
  for _,p in ipairs(Plugins) do
    if p.handle and (exact or p.GInfo.Guid~=selfId) then
      local res = ""
      if far.UnloadPlugin(p.handle) then
        if cacheFn then cacheFn(p) end
        unloaded_counter = unloaded_counter+1
      else
        res = "Failed!"
      end
      print(p.GInfo.Title, res)
    end
  end
  local tmpl = arg and "[%s: %s]" or "[%s]"
  print(("Total: %i plugins unloaded"):format(unloaded_counter),
        tmpl:format(source, arg))
end

local nargs = select('#', ...)
local batch = nargs>0 and select(nargs, ...)=="batch"
if exact or batch then
  unloadBatch()
else
  sh.plugins.List({
    Title="Unload plugin:",
    Id=win.Uuid"EF4EEE0C-8717-4CB8-9A65-AED9095DD26A",
    markUnloaded="✗x",
    batchFn=unloadBatch
  }, Plugins)
end
