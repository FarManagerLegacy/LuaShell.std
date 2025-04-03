-- toggle option
assert(actl.GetWindowType().Type==far.Flags.WTYPE_PANELS, "Meant to be run in panels")
local item = "Interface.VirtualTerminalRendering"
mf.print "far:config"
Far.DisableHistory(1)
Keys"Enter"
assert(Area.Dialog)
assert(Menu.Select(item,1)~=0)
Keys"F4"
local MARKED = 2
Keys"Esc"
print(item..":", Far.GetConfig(item) and "enabled" or "disabled")
