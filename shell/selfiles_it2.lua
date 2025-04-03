-- - код сложнее, поскольку по сути приходится переизобретать panel.GetSelectedPanelItem
-- - (теоретически) медленнее чем если бы использовалась panel.GetSelectedPanelItem
-- + итерация не сбивается от изменений выделения в процессе обработки
-- + предоставляет индекс файла на панели (см. https://bugs.farmanager.com/view.php?id=3984)
local F = far.Flags

local function iter (handle,i)
  repeat
    i = i+1
    local file = panel.GetPanelItem(handle,nil,i)
    if file and bit64.band(file.Flags, F.PPIF_SELECTED)==F.PPIF_SELECTED then
      return i,file
    end
  until not file
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
  elseif pi.SelectedItemsNumber==1 then
    local file = panel.GetSelectedPanelItem(handle,nil,1)
    if bit64.band(file.Flags,F.PPIF_SELECTED)==0 then -- CurrentItem
      -- https://api.farmanager.com/ru/service_functions/panelcontrol.html#FCTL_GETSELECTEDPANELITEM
      local itemIdx = pi.CurrentItem
      return function (_,i)
        if i==0 then return itemIdx,file end
      end, handle, 0
    end
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
]]
  end
end
