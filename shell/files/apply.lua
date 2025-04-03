--[[
.Language=Russian,Russian (Русский)
.PluginContents="Process/select files"
@Contents
$ #Process/select files#
 Универсальный выбор/обработка файлов, удовлетворяющих заданному условию.
 Можно ограничить обработку файлами/директориями/выделением/условием а также ~маской~@:FileMasks@
или ~фильтром~@:FiltersMenu@.
 Есть возможность выделить, снять выделение, или выполнить какое-либо другое действие, заданное скриптом.

 #Code to apply to each file#
   Код для выполнения, #lua#/#moon-#/#yue-#выражение.
   Альтернативно: можно указать имя скрипта, содержащего код.

   Если результат выполняемого выражения `true`, то для файла устанавливается / снимается выделение (в зависимости
от состояния чекбокса #[ ] Deselect#).
   Помимо кнопки #[ OK ]# / #Enter# запустить обработку файлов можно с помощью шорткатов #Alt+Add#/#Alt+Subtract#,
которые также определяют выполняемое действие.

   При выполнении кода вся информация об обрабатываемом файле доступна в окружении:
   - Все поля структуры ~PluginPanelItem~@https://api.farmanager.com/ru/structures/pluginpanelitem.html@.
   - Индекс обрабатываемого файла #idx#.
   Также доступна возможность обращаться к скриптам ~LuaShell~@https://forum.farmanager.com/viewtopic.php?f=15&t=10907@
(через таблицу #sh#).

 #Initial code#
   Код (или имя скрипта), выполняемый перед обработкой.
   Например, так в окружении можно определить вспомогательные функции, или инициализировать переменные.
   В качестве примера использования см. скрипт #_init.lua# из дистрибутива.

 #Final code#
   Код (или имя скрипта), выполняемый после обработки.
   Скрипт получает значения, возвращённые #sh.files_process#.
   В качестве примера использования см. скрипт #_totals.lua# из дистрибутива.

 #Condition#
   Код (или имя скрипта), выполняемый когда выбрана опция #(•) Condition#.
   Если для файла не возвращается `true`, то его обработка не проводится.
   Скрипт получает в окружении те же данные о файле, что и основной код (см. #Code to apply...#).

@=
 #Примечания#:
 - Если в поле ввода находится имя какого-либо скрипта, то #F3#/#F4# позволяют открыть его во вьюере/редакторе.
   Если скрипт с таким именем не существует, то по #F4# будет предложено его создать.
 - Ошибки, возникающие при выполнении #Code to apply...# и #Condition#, выводятся в консоль, и не прерывают обработку.
   Ошибки, возникающие при выполнении #Initial# и #Final code# обрабатываются обычным образом.
 - Во время отладки кода может быть удобно воспользоваться опцией #(•) Current only#.
   Шорткат #Ctrl+Enter# запускает обработку именно с этой опцией.

 #Дополнительно#:
   ~Программный вызов~@API@
   ~Использование в макросах~@Macro@

@=-
 Навеяно ~задачей~@https://forum.farmanager.com/viewtopic.php?t=13253@ выделения файлов со слишком длинными именами.
 Например для решения той задачи достаточно запустить:# ##FileName>255#.

@API
$ #Программный вызов#
 Syntax:
   #sh.files(options)#

 #options#: table with following optional fields:
   #deselect#, #filesOnly#, #dirsOnly#, #useMask#, #selOnly#, #curOnly#, #condition#, #useFilter#, #noLimits#: boolean
   #code#, #init#, #fin#, #cond#, #mask#: string
   #env#: table

@Macro
$ #Использование в макросах#
 Для вызова скрипта макросом необходимо использовать модуль #sh#, предоставляемый
~LuaShell~@https://forum.farmanager.com/viewtopic.php?f=15&t=10907@.

 #Пример 1#:

@-
 Macro {
   description="Process files";
   area="Shell"; key="CtrlShiftG";
   action=function()
     require"sh".apply()
   end;
 }
@+


 #Пример 2#: используя ~API~@API@ можно открыть диалог с предварительно заполненными полями,
и окружением (в котором например могут быть определены пользовательские функции, и т.п.)

@-
 local env = {}
 env.path = function(FileName)
   return far.ConvertPath(FileName, "CPM_NATIVE")
 end
 Macro {
   description="Process/select files with lua code";
   area="Shell"; key="CtrlShiftG";
   action=function()
     require"sh".apply {
       useMask=true,
       mask="*.lua",
       code="print idx, path FileName",
       env=env,
     }
   end;
 }
@+

@
--]]
local F = far.Flags

local DlgGuid = win.Uuid"69BE21F9-0483-4783-98C4-804E0B0F8C41"
local defaultOpt = {filesOnly=true}

local M = {
  title="Process/select files",
  promptCode="&Code to apply to each file",
  promptInit="&Initial code",
  promptFin="Fina&l code",
  deselect="Deselect &-",
  filesOnly="&Files only",
  dirsOnly="&Directories only",
  useFilter="&Use filter",
  selOnly="&Selected only",
  curOnly="Current &only",
  noLimits="&No limits",
  useMask="&Mask",
  condition="Condi&tion",
  ok="OK",
  filter="Filt&er…",
  cancel="Cancel",
  warning="Warning",
  codeError="Code error",
  noEmptyCode="Code cannot be empty",
}

-- indexes
local edt, edtMask, opts = {}, nil, {}
local btnOK, btnFilter

local filter, fn, env, opt -- globals
local function getFn (hDlg)
  fn = {}
  for key,pos in pairs(edt) do
    local code = hDlg:send(F.DM_GETTEXT, pos)
    if code:match"^%s*$" then
      if pos==edt.code or pos==edt.cond and hDlg:send(F.DM_GETCHECK, opts.condition)==1 then
        hDlg:send(F.DM_SETFOCUS, pos)
        far.Message(M.noEmptyCode, M.warning, nil, "w")
        return false
      end
    else
      local fullname = sh.findScript(code)
      local err
      if fullname then
        fn[key], err = sh.loadfile(fullname,env)
      else
        fn[key], err = sh.loadstring(code, key..": "..code, env)
      end
      if not fn[key] then
        hDlg:send(F.DM_SETFOCUS, pos)
        far.Message(err, M.codeError, nil, "w")
        return false
      end
    end
  end
end
local function prepEnv (file,idx)
  for k,v in pairs(file) do env[k] = v end
  env.idx = idx
end
local function prepOpt (hDlg,mask)
  opt = {}
  for name,idx in pairs(opts) do
    opt[name] = hDlg:send(F.DM_GETCHECK, idx)==1
  end
  if opt.useFilter then
    opt.useFilter = function(file)
      return filter:IsFileInFilter(file)
    end
  elseif opt.mask then
    opt.mask = function(file)
      return far.ProcessName(F.PN_CMPNAMELIST, mask, file.FileName, F.PN_SKIPPATH)
    end
  elseif opt.cond then
    opt.cond = function(...)
      prepEnv(...)
      return fn.cond()
    end
  end
  if not opt.cond then
    local fn1 = fn.code
    function fn.code (...) prepEnv(...); return fn1() end
  end
end
local function DlgProc (hDlg,Msg,idx,Rec)
  if Msg==F.DN_BTNCLICK then
    if idx==btnFilter then
      filter:OpenFiltersMenu()
    end
  elseif Msg==F.DN_CLOSE then
    if idx==btnOK then
      if getFn(hDlg)==false then return false end
      local mask = hDlg:send(F.DM_GETTEXT, edtMask)
      if (mask~="" or hDlg:send(F.DM_GETCHECK, opts.useMask)==1) and
         not far.ProcessName(F.PN_CHECKMASK, mask, nil, F.PN_SHOWERRORMESSAGE) then
        hDlg:send(F.DM_SETFOCUS, edtMask)
        return false
      end
      prepOpt(hDlg,mask)
      sh._shared[_filename] = opt
    end
  elseif Msg==F.DN_CONTROLINPUT then
    local key = far.InputRecordToName(Rec)
    if key=="F1" then
      far.ShowHelp(_filename, nil, F.FHELP_CUSTOMFILE + F.FHELP_NOSHOWERROR)
    elseif key=="AltAdd" then
      hDlg:send(F.DM_SETCHECK, opts.deselect, 0)
      hDlg:send(F.DM_CLOSE, btnOK)
    elseif key=="AltSubtract" then
      hDlg:send(F.DM_SETCHECK, opts.deselect, 1)
      hDlg:send(F.DM_CLOSE, btnOK)
    elseif key=="CtrlEnter" then
      hDlg:send(F.DM_SETCHECK, opts.curOnly, 1)
      hDlg:send(F.DM_CLOSE, btnOK)
    end
  end
end

local function assertType (v, ...)
  local name = type(v)
  for i=1,select("#", ...) do
    if select(i, ...)==name then return v end
  end
  local names = table.concat({...}, " or ")
  error(names.." expected, got "..type(v), 2)
end

local function add (self,item)
  item[6] = item[5] or item.Selected and 1 or 0
  item[7] = item.History or 0
  item[8] = item.Mask or 0
  item[9] = item[4] or nil -- Flags
  item[10] = item[2] -- Data
  --item[11] = item.MaxLength
  --item[12] = item.UserData
  local coords = item[3]
  coords[4] = coords[4] or coords[2] -- y2==y1
  for i=2,5 do item[i] = coords[i-1] or 0 end
  local i = #self+1; self[i] = item; return i
end

local function Apply (options)
  local width = 80
  local height = 13
  local _1 = 5
  local _2 = 30
  local _3 = 52
  local mid = width/2-1 + _1
  local dpos = width-M.deselect:len()-1 --right aligned
  local Items = {add=add}
  local II = Items
  local edtFlags = F.DIF_HISTORY +F.DIF_USELASTHISTORY
  local edtFlagsEx = edtFlags +F.DIF_EDITPATHEXEC
--[[01]]                  II:add {F.DI_DOUBLEBOX,   M.title,        {3, 1, width+2, height}}
--[[02]] opts.deselect  = II:add {F.DI_CHECKBOX,    M.deselect,   {dpos,2}}
--[[02]]                  II:add {F.DI_TEXT,        M.promptCode,  {_1, 2}}
--[[03]] edt.code       = II:add {F.DI_EDIT,        "",            {_1, 3, width}, edtFlagsEx +F.DIF_HOMEITEM,
                                  History="ProcessFilesDlgCode"}
--[[04]]                  II:add {F.DI_TEXT,        M.promptInit,  {_1, 4}}
--[[05]] edt.init       = II:add {F.DI_EDIT,        "",            {_1, 5, mid-3}, edtFlagsEx,
                                  History="ProcessFilesDlgInit"}
--[[04]]                  II:add {F.DI_TEXT,        M.promptFin,  {mid, 4}}
--[[05]] edt.fin        = II:add {F.DI_EDIT,        "",           {mid, 5, width}, edtFlagsEx,
                                  History="ProcessFilesDlgFin"}
--[[06]]                  II:add {F.DI_TEXT,        "",             {0, 6}, F.DIF_SEPARATOR}
--[[07]] opts.filesOnly = II:add {F.DI_RADIOBUTTON, M.filesOnly,   {_1, 7}}
--[[08]] opts.dirsOnly  = II:add {F.DI_RADIOBUTTON, M.dirsOnly,    {_1, 8}}
--[[09]] opts.useMask   = II:add {F.DI_RADIOBUTTON, M.useMask,     {_1, 9}}
--[[07]] opts.selOnly   = II:add {F.DI_RADIOBUTTON, M.selOnly,     {_2, 7}}
--[[08]] opts.curOnly   = II:add {F.DI_RADIOBUTTON, M.curOnly,     {_2, 8}}
--[[09]] opts.condition = II:add {F.DI_RADIOBUTTON, M.condition,   {_2, 9}}
--[[07]] opts.useFilter = II:add {F.DI_RADIOBUTTON, M.useFilter,   {_3, 7}}
--[[08]] opts.noLimits  = II:add {F.DI_RADIOBUTTON, M.noLimits,    {_3, 8}}
--[[10]] edtMask        = II:add {F.DI_EDIT,        "",          {_1+4,10, _2-3}, edtFlags,
                                  History="Masks"}
--[[10]] edt.cond       = II:add {F.DI_EDIT,        "",          {_2+4,10, width}, edtFlagsEx,
                                  History="ProcessFilesDlgCond"}
--[[11]]                  II:add {F.DI_TEXT,        "",             {0,11}, F.DIF_SEPARATOR}
--[[12]] btnOK          = II:add {F.DI_BUTTON,      M.ok,           {0,12}, F.DIF_CENTERGROUP +F.DIF_DEFAULTBUTTON}
--[[12]] btnFilter      = II:add {F.DI_BUTTON,      M.filter,       {0,12}, F.DIF_CENTERGROUP +F.DIF_BTNNOCLOSE}
--[[12]]                  II:add {F.DI_BUTTON,      M.cancel,       {0,12}, F.DIF_CENTERGROUP}
  env = nil
  if options~=nil then
    assertType(options, "table")
    for k,pos in pairs(edt) do
      Items[pos][10] = assertType(options[k], "nil", "string")
    end
    Items[edtMask][10] = assertType(options.mask, "nil", "string")
    env = assertType(options.env, "nil", "table")
  else
    options = sh._shared[_filename] or defaultOpt
    options.deselect = nil
  end
  env = env or {}
  for k,pos in pairs(opts) do
    Items[pos][6] = options[k] and 1 or 0
  end
  filter = far.CreateFileFilter(1, F.FFT_SELECT)
  local ret = far.Dialog(DlgGuid, -1, -1, width+6, height+2, nil, Items, nil, DlgProc)
  if ret==btnOK then
    if fn.init then fn.init() end
    local counter,fails,selected
    if opt.curOnly then
      local handle = F.PANEL_ACTIVE
      local idx = panel.GetPanelInfo(handle).CurrentItem
      local file = panel.GetPanelItem(handle, nil, idx)
      selected = fn.code(file,idx)==true and 1 or 0
      counter,fails = 1,0
    else
      counter,fails,selected = sh.files_process(fn.code, opt)
    end
    if fn.fin then fn.fin(counter,fails,selected) end
  end
  filter:FreeFileFilter()
  return opt and env
end

if _cmdline then
  if Area.Shell then sh.acall(Apply, sh.eval(_cmdline)) end
else
  return Apply
end
