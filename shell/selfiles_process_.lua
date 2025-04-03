local F = far.Flags
function path (file) --luacheck: allow defined top
  return far.ConvertPath(file.FileName, F.CPM_NATIVE)
end

local mt = {__index=getfenv()}
local function selfiles_process (fn, handle)
  if type(handle)=="string" then
    handle = F[handle] or F["PANEL_"..handle:upper()]
  else
    handle = handle or F.PANEL_ACTIVE
  end
  assert(handle,"wrong panel handle")
  setfenv(fn, setmetatable({}, mt))
  panel.BeginSelection(handle) -- to be able to restore selection with CtrlM
  for _=1, panel.GetPanelInfo(handle).SelectedItemsNumber do
    local file = panel.GetSelectedPanelItem(handle, nil, 1)
    local success, msg = pcall(fn, file)
    if not success then
      print("Error with file:", file.FileName)
      print(msg)
      break
    end
    panel.ClearSelection(handle,nil,1)
  end
  panel.EndSelection(handle)
  panel.RedrawPanel(handle)
end

if not _cmdline then
  return selfiles_process
else --testing
  if Area.Shell and _cmdline~="" then
    print "testing selfiles_process:"
    selfiles_process(function (file)
      --error"some error"
      print(path(file), sh.dump(file))
    end,...)
  else
    print [[
Process selected files with specified function, clearing selection, unless error
Breakes iteration in case of error.

Syntax:
  sh.selfiles_process(fn[, handle])

handle: optional string 'active'/'passive'
fn (file): function to execute
  file: table, tPluginPanelItem (luafar_manual.chm::/85.html)
  [environment]:
    path (file): function
      returns: fullpath to file (using far.ConvertPath)
]]
  end
end
