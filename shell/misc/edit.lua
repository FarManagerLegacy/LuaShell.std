-- Usage: edit <scriptname>
-- Without arguments:
-- * Editor: edit file specified under cursor
-- * Other areas: edit LuaShell.lua
local def_ext = ".lua"
local def_path = sh._shared.options.path or ""

local function edit (name)
  local CP_UTF8 = 65001
  local CP
  if type(name)~="string" then
    error "`name` arg required"
  end
  local script,err = sh.findScript(name)
  if err then
    local n = name:lower()
    local need_ext = not far.ProcessName(far.Flags.PN_CMPNAMELIST, "*.lua;*.moon;*.yue", n) and ".&lua;.&moon;.&yue"
    local ans = far.Message(err.."\nCreate new?",sh._shared.info.name,need_ext or nil)
    if ans==-1 then return end
    if need_ext then name = name..({".lua",".moon",".yue"})[ans] end
    script = name:match"[\\/]" and name or def_path..name
    CP = CP_UTF8 --default
  end
  local EF = {EF_NONMODAL=1; EF_IMMEDIATERETURN=1}
  return editor.Editor(script,nil,nil,nil,nil,nil,EF,nil,nil,CP)
end

if _cmdline then
  local name = _cmdline
  if name=="" then
    if Area.Editor then
      name = sh.pick()
    else
      name = debug.getinfo(print).source:sub(2)
    end
  end
  edit(name)
else
  return edit
end
