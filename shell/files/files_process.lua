local F = far.Flags
--luacheck: allow defined top
function path (file)
  return far.ConvertPath(file.FileName, F.CPM_NATIVE)
end

function selOnly (file) --luacheck: ignore
  return bit64.band(file.Flags, F.PPIF_SELECTED)==F.PPIF_SELECTED
end

function dirsOnly (file) --luacheck: ignore
  return file.FileAttributes:find"d"
end

function filesOnly (file) --luacheck: ignore
  return not file.FileAttributes:find"d"
end
--luacheck: no allow defined top

local __ENV = getfenv()
__ENV.F = F
local mt = {__index=__ENV}
local function files_process (fn, opt)
  local handle = F.PANEL_ACTIVE
  opt = opt or {}
  if type(opt)=="string" then
    opt = {[opt]=true}
  end
  setfenv(fn, setmetatable({}, mt))
  local cond
  for fname,f in pairs(opt) do
    cond = f and (type(f)=="function" and f or __ENV[fname])
    if cond then break end
  end
  local counter,fails,selected = 0,0,0
  panel.BeginSelection(handle) -- to be able to restore selection with CtrlM
  for idx=1, panel.GetPanelInfo(handle).ItemsNumber do
    local file = panel.GetPanelItem(handle, nil, idx)
    if idx~=1 or file.FileName~=".." then
      local passed, success, msg = true
      if cond then
        success, msg = pcall(cond, file, idx)
        passed = success and msg
      end
      if passed then
        success, msg = pcall(fn, file, idx)
      end
      if not success then
        fails = fails+1
        print("Error with file:", file.FileName)
        print(msg)
        if opt.breakOnError then break end
      elseif passed then
        counter = counter+1
        if msg==true then
          selected = selected+1
          panel.SetSelection(handle, nil, idx, not opt.deselect)
        end
      end
    end
  end
  panel.EndSelection(handle)
  panel.RedrawPanel(handle)
  return counter,fails,selected
end

if not _cmdline then -- export
  return files_process
elseif not Area.Shell or _cmdline=="" then
  print [[
Process files with specified function, (de)selecting files,
when function returns `true`.

Usage:
  sh.files_process(fn,opt)

    fn (file, idx): function to execute
      file: table, tPluginPanelItem (mk:@MSITStore:%FARHOME%\Encyclopedia\luafar_manual.chm::/85.html)
      [environment]:
        path (file): function
          returns: fullpath to file (using far.ConvertPath)
        idx: number
      returns: if exactly `true` then (de)select file

    opt: table of options
      deselect: boolean
      breakOnError: boolean
      selOnly, dirsOnly, filesOnly: boolean (name corresponding to filter function in env)
      <anyname>: function, to use as filter (args same as for fn)
      Note: only one filter is allowed

    opt: string, name corresponding to any option

    returns: counter,fails,selected

Syntax (when called from command line):
  files_process fn, opt
   or
  files_process opt, fn
]]
elseif _cmdline=="test" then
  print "testing files_process:"
  files_process(function (file,idx)
    --error"some error"
    print(idx, path(file), sh.dump(file))
  end,...)
else
  local fn, opt = sh.eval(_cmdline)
  if type(opt)=="function" then
    fn,opt = opt,fn
  end
  assert(type(fn)=="function", "fn function expected")
  files_process(fn,opt)
end
