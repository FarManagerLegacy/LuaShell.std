local F = far.Flags
function path (file) --luacheck: allow defined top
  return far.ConvertPath(file.FileName, F.CPM_NATIVE)
end

local mt = {__index=getfenv()}
local function selfiles_process (fn, handle, breakOnError)
  if type(handle)=="string" then
    handle = F[handle] or F["PANEL_"..handle:upper()]
  else
    handle = handle or F.PANEL_ACTIVE
  end
  assert(handle,"wrong panel handle")
  setfenv(fn, setmetatable({}, mt))
  panel.BeginSelection(handle) -- to be able to restore selection with CtrlM
  local selected = 0
  local errored
  for _=1, panel.GetPanelInfo(handle).SelectedItemsNumber do
    local file = panel.GetSelectedPanelItem(handle, nil, 1+selected)
    local success, msg = pcall(fn,file)
    if success then
      if msg==true then
        selected = selected+1
      else
        panel.ClearSelection(handle,nil,1)
      end
    else
      print("Error with file:", file.FileName)
      print(msg)
      errored = true
      if breakOnError then break end
      selected = selected+1
    end
  end
  panel.EndSelection(handle)
  panel.RedrawPanel(handle)
  return not errored
end

if not _cmdline then -- export
  return selfiles_process
else -- testing
  if Area.Shell and _cmdline~="" then
    print "testing selfiles_process:"
    selfiles_process(function (file)
      --error"some error"
      print(path(file), sh.dump(file))
    end,...)
  else
    print [=[
Process selected files with specified function, clearing selection,
unless the function returns `true`.
Files caused errors remain selected as well.

Usage:
  sh.selfiles_process(fn[, handle, [breakOnError]])

returns true if there were no errors in fn processing

handle: optional string 'active'/'passive'

breakOnError: boolean; optional

fn (file): function to execute
  file: table, tPluginPanelItem (luafar_manual.chm::/85.html)
  [environment]:
    path (file): function
      returns: fullpath to file (using far.ConvertPath)
  returns: if exactly `true` then keep file selected
]=]
  end
end
