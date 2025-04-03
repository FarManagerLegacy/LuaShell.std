local F = far.Flags

local function iter (handle,i)
  i = i+1
  local file = panel.GetSelectedPanelItem(handle, nil, i)
  if file then return i,file end
end

local function selfiles_it (handle)
  if type(handle)=="string" then
    handle = F[handle] or F["PANEL_"..handle:upper()]
  else
    handle = handle or F.PANEL_ACTIVE
  end
  local pi = panel.GetPanelInfo(assert(handle,"wrong panel handle"))
  if pi.SelectedItemsNumber==0 then -- ".."
    -- https://api.farmanager.com/ru/structures/panelinfo.html#SelectedItemsNumber
    return function()end
  end
  return iter,handle,0
end

if not _cmdline then
  return selfiles_it
else --testing
  if Area.Shell and _cmdline~="" then
    print "testing selfiles_it on selection:"
    for idx,file in selfiles_it(...) do
      print(idx, file.FileName)
    end
  else
    print [[
Selected files iterator for panels

Usage:
  for idx,file in sh.selfiles_it(handle) do ... end

handle: optional string 'active'/'passive'

Note: Changing selection during processing will lead to undefined behavior!
]]
  end
end
