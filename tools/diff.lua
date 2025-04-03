assert(_cmdline, "meant to be executed directly")
local F = far.Flags
local function notPlugin(Panel)
  return not Panel.Plugin or bit64.band(Panel.OPIFlags,F.OPIF_REALNAMES)~=0,"Plugin panel not supported"
end
local function Selected(act,i)
  return panel.GetSelectedPanelItem(nil,act,i).FileName
end

local a,b
assert(notPlugin(APanel))

local ACTIVE,PASSIVE = 1,0
if APanel.SelCount==2 then
  a,b = Selected(ACTIVE,1), Selected(ACTIVE,2)

else
  assert(notPlugin(PPanel))
  a = APanel.SelCount==1 and Selected(ACTIVE,1) or APanel.Current
  local isTmpPanel = PPanel.Path==""
  if PPanel.SelCount==1 then
    b = Selected(PASSIVE,1)
    if not isTmpPanel then
      b = PPanel.Path.."\\"..b
    end
  else
    if isTmpPanel then
      error"File must be selected on plugin panel"
    elseif APanel.Path==PPanel.Path then
      error"Two files must be selected on same panel"
    end
    local name = a:match"[^\\/]*$" -- can be fullpath
    b = PPanel.Path.."\\"..name
    assert(win.GetFileAttr(b),("%q does not exist"):format(b))
  end
end

if _cmdline=="" then
  local VisComp = "AF4DAB38-C00A-4653-900E-7A8230308010"
  Plugin.Command(VisComp,('"%s" "%s"'):format(a,b))
else
  mf.print(_cmdline)
  mf.print((' "%s" "%s"'):format(a,b))
  Keys"Enter"
end
