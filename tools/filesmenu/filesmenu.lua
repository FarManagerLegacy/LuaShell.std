--v.1.1.1 --https://forum.farmanager.com/viewtopic.php?p=145820#p145820
assert(not sh or _cmdline, "meant to be executed directly")
if _cmdline=="" then
  return print [[
filesmenu <mask> <cmd> <path> <FRS flags>

В папке <path> (по умолчанию ".") рекурсивно ищет файлы подходящие под <mask> (по умолчанию *.exe).
Найденные отображает в виде меню, при выборе — запускает в командной строке, предваряя
командой <cmd> (если задана).
Кроме того, в меню доступны клавиши F3, F4, CtrlPgUp, служащие для вставки префиксов
view:, edit:, goto:.
В качестве <FRS flags> можно задать "FRS_NONE" или "FRS_RECUR" (а по умолчанию FRS_RECUR|FRS_SCANSYMLINK)

Пример использования, через консольные алиасы:
-----
cc=luash:filesmenu changelog* edit: "%FARHOME%\Plugins"
chm=luash:filesmenu *.chm "" "%FARHOME%\Encyclopedia"
gg=luash:filesmenu $*
ggg=luash:filesmenu $* "" "" FRS_NONE
-----

сс — список changelog* из папки Plugins
chm — список chm-файлов из папки Encyclopedia
gg <mask> — список файлов <mask> в текущей папке с подпапками
ggg <mask> — список файлов <mask> в текущей папке
]]
end

local def_path,def_mask = ".\\","*.exe"
local mask,command,path,FRS_flags = ...
if not mask or mask=="" then mask = def_mask end
if not path or path=="" then path = def_path end
FRS_flags = FRS_flags or {FRS_RECUR=1,FRS_SCANSYMLINK=1}

local function ExpandEnv(str) return (str:gsub("%%(.-)%%", win.GetEnv)) end
path = ExpandEnv(path)
if not path:match"[\\/]$" then path = path.."\\" end
local dir_attr = win.GetFileAttr(path)
if not dir_attr or not dir_attr:find"d" then
  far.Message("Path not found: "..path,"Error",nil,"w")
  return
end

local s = far.SaveScreen()
far.Message(mask,"Searching...","")

local F = far.Flags
local files = {}
local function CheckKey(vk)
  local vk_pressed
  repeat
    local key = win.ExtractKey()
    vk_pressed = vk_pressed or key==vk
  until not key
  return vk_pressed
end

--http://bugs.farmanager.com/view.php?id=3494
local MAXFOUND = 1000
local TIMEOUT = 100000
local time = far.FarClock()
far.RecursiveSearch(path,mask,function(Item,fullname)
  local i = #files+1
  if CheckKey"ESCAPE" then
    if i>1 then files[i] = {text="...search was interrupted...",disable=true} end
    return true
  end
  if i>MAXFOUND then
    files[i] = {text="...there were more files...",disable=true}
    return true
  end
  local newtime = far.FarClock()
  if newtime-time>TIMEOUT then
    time = newtime
    far.Message(mask,("Searching... (%i)"):format(i),"")
  end
  files[i] = {
    text=fullname:gsub(path,"",1),
    fullname=fullname,
    checked=Item.FileAttributes:find"d" and "\\",
  }
end,FRS_flags)

if #files==0 then far.RestoreScreen(s); return end --todo or message

local cmds = {
  Enter    = command,
  CtrlPgUp = "goto:",
  CtrlNum9 = "goto:",
  F3       = "view:",
  F4       = "edit:",
}
local brkeys = {}
for key,cmd in pairs(cmds) do
  brkeys[#brkeys+1] = {
    BreakKey=key,
    cmd=cmd,
  }
end

local set,lock,notempty = 0,1,2 -- first arg of Menu.Filter()
mf.postmacro(Menu.Filter,set,1) -- Keys,"RAlt"

local Id = win.Uuid"AB83DA34-8AB3-4AFA-8702-80DBF516011D"
local item,pos = far.Menu({Title=mask,Bottom="Enter, F3, F4, CtrlPgUp",Id=Id},files,brkeys)
far.RestoreScreen(s)
if item then
  local choosen = files[pos]
  command = item.cmd or command or ""
  mf.postmacro(function()
    Far.DisableHistory(-1)
    panel.SetCmdLine(nil,command..choosen.fullname)
    --mf.print(command..choosen.fullname)
    Keys "Enter"
  end)
end
