--https://forum.farmanager.com/viewtopic.php?f=15&t=12381
if not APanel.Selected then
  print "(re)Load macros from selected folders"
  return
end

local paths = {}
local success = sh.selfiles_process(function(item)
  assert(item.FileAttributes:find("d"), "not a directory")
  table.insert(paths,item.FileName)
end, nil, "breakOnError")

if success then
  far.MacroLoadAll(table.concat(paths, ";"))
  sh.toast"Success!"
end
