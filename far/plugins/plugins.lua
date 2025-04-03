--[[
.Language=English,English (English)
.PluginContents=Plugins utils

@Contents
$ #Plugins dialog#

 #Legend:#
 ───────
  #+#  - cached
  #√#  - loaded
  #*#  - preloaded
  #x#  - not loaded
 #[A]# - Far 1.x plugin
       Note: when using #load.lua# util, the exteded info for Far 1.x dlls
             becomes available upon plugin loading only.


 #Keys:#
 ─────
 #Enter#       - load/unload toggle
 #Ctrl+Enter#  - apply action to all plugins in the list
               The action must be provided by external script, such as #load.lua# / #unload.lua#,
               and not available when launched via #plugins.lua#
 #Shift+Enter# - force load plugin
 #Ctrl+PgUp#   - goto plugin dll
 #F3#          - plugin info
 #F5#          - run (menu item)
 #Del#         - remove plugin info from plugins cache (plugincache.*.db)
               For this function #lsqlite3# module required.
               The module is included in the ~Polygon~@https://github.com/shmuz/far_plugins/releases?q=polygon&expanded=true@ distrib.
               Note: for this function to work plugin must not be (pre)loaded.
@
--]]

local F = far.Flags
local function fmtTitle (info)
  local title = info.GInfo and info.GInfo.Title
                            or "> No data: "..info.ModuleName:match"[^\\]+$"
  if info.Flags then
    if band(info.Flags, F.FPF_ANSI)~=0 then title = title.." [A]" end
  end
  return title
end

local stage = {"alpha","beta","RC"}
local function fmtVer (ver)
  local str = table.concat(ver,".",1,3)
  if ver[4]~= 0 then str = str..(" (build %i)"):format(ver[4]) end
  if ver[5]~= 0 then str = str.." "..(stage[ver[5]] or ver[5]) end
  return str
end

local function fmtChecked (info)
  return band(info.PInfo.Flags, F.PF_PRELOAD)~=0 and "•*"
      or band(info.Flags, F.FPF_LOADED)~=0 and "✓√"
end

local function fmtItem (item, mark)
  item.text = fmtTitle(item)
  item.checked = mark or item.handle and fmtChecked(item)
  item.grayed = not win.GetFileAttr(item.ModuleName) or nil
  return item
end

local function getPlugins ()
  local plugins = {}
  for item,handle in sh.plugins_it() do
    item.handle = handle
    plugins[#plugins+1] = item
  end
  return plugins
end

local function getCachedPlugins (Cache)
  local plugins = {}
  for _,item in pairs(Cache) do
    plugins[#plugins+1] = item
  end
  return plugins
end

local function fmtPlugins (plugins, mark)
  for i=1,#plugins do fmtItem(plugins[i], mark) end
  table.sort(plugins, function (a,b)
    return a.text:lower() < b.text:lower()
  end)
end

local function showInfo (info)
  local status = not info.handle and "<not loaded>"
    or band(info.Flags, F.FPF_LOADED)~=0 and "Loaded"
    or "Cached"
  if info.PInfo and band(info.PInfo.Flags, F.PF_PRELOAD)~=0 then
    status = status.." (Preload)"
  end
  if info.Flags and band(info.Flags, F.FPF_ANSI)~=0 then
    status = status.." [Ansi]"
  end
  local str = info.GInfo and next(info.GInfo) and
([[
Description │ %s
Author      │ %s
Version     │ %s
UUID        │ %s
Prefix      │ %s
Status:     │ %s
%s
%s]]):format(
  info.GInfo.Description,
  info.GInfo.Author,
  fmtVer(info.GInfo.Version) or "",
  win.Uuid(info.GInfo.Guid):upper() or "",
  info.PInfo and info.PInfo.CommandPrefix or "N/A",
  status,
  "\1",
  info.ModuleName) or "Status: "..status
  far.Message(str, info.GInfo and info.GInfo.Title or info.ModuleName, nil, "l")
end

local getCache, cacheFn
if pcall(function() return sh.cachedb end) then
  getCache = sh.cachedb.getCache
else
  local Cache = sh._shared[_filename]
  if not Cache then
    Cache = {}
    sh._shared[_filename] = Cache
  end
  function getCache ()
    return Cache
  end
  function cacheFn (item) -- store item in cache
    Cache[item.ModuleName] = item
  end
end

local function List (props, Plugins, Cache) --Title,Id,mark*,batchFn
  fmtPlugins(Plugins)
  if Cache and next(Cache) then
    if not Cache[1] then
      for _,item in ipairs(Plugins) do
        local c = Cache[item.ModuleName]
        if c then
          item.id = c.id
          Cache[item.ModuleName] = nil
        end
      end
      Cache = getCachedPlugins(Cache)
      fmtPlugins(Cache, props.markUnloaded)
    else
      fmtPlugins(Cache)
    end
    if #Plugins>0 then
      Plugins[#Plugins+1] = {separator=true}
    end
    for _,item in ipairs(Cache) do
      Plugins[#Plugins+1] = item
    end
  end
  props.Bottom = "F1, F3, F5"
  local breakKeys = "ShiftEnter CtrlPgUp F1 F3 F5 AltF3 Del"
  if props.batchFn then
    props.Bottom = props.Bottom..", Ctrl+Enter: batch"
    breakKeys = breakKeys.." CtrlEnter"
  end
  repeat
    local item,pos = far.Menu(props, Plugins, breakKeys)
    if not item then break end
    local LoadPlugin
    if not item.BreakKey then
      LoadPlugin = far.LoadPlugin
    elseif item.BreakKey=="CtrlEnter" then
      props.batchFn(cacheFn)
      break
    elseif item.BreakKey=="ShiftEnter" then
      LoadPlugin = far.ForcedLoadPlugin
      item = Plugins[pos]
    elseif item.BreakKey=="CtrlPgUp" then
      item = Plugins[pos]
      if item then
        local dir,name = item.ModuleName:match("^(.+\\)(.-)$")
        panel.SetPanelDirectory(nil,1,dir) --see mbrowser.lua/LocateFile
        Panel.SetPath(0,dir,name)
        break
      end
    elseif item.BreakKey=="F1" then
      far.ShowHelp(_filename, nil, F.FHELP_CUSTOMFILE + F.FHELP_NOSHOWERROR)
    elseif item.BreakKey=="F3" then
      --if Plugins[pos].GInfo then
        showInfo(Plugins[pos])
      --end
    elseif item.BreakKey=="AltF3" then --debug
      require"le"(Plugins[pos])
    elseif item.BreakKey=="F5" then
      local guid = win.Uuid(Plugins[pos].GInfo.Guid)
      if Plugin.Menu(guid) then break end
    elseif item.BreakKey=="Del" then
      item = Plugins[pos]
      local loaded = item.handle and band(item.Flags, F.FPF_LOADED)~=0
      if not loaded and item.id then
        if sh.cachedb.cleanCache(item.id) then
          item.id = nil
          if not item.handle then
            table.remove(Plugins,pos)
          end
        else
          mf.beep()
        end
      else
        mf.beep()
      end
    end
    if not LoadPlugin then
      --nop
    elseif not item.handle or LoadPlugin==far.ForcedLoadPlugin then
      local ModuleName = item.ModuleName
      local handle = LoadPlugin(F.PLT_PATH, ModuleName)
      if handle then
        item = far.GetPluginInformation(handle)
        if not item then
          far.Message(ModuleName, "Plugin loading failed", nil, "w")
        else
          item.handle = handle
          item.checked = props.markLoaded or fmtChecked(item)
          item.text = fmtTitle(item)
          Plugins[pos] = item
        end
      end
    elseif far.UnloadPlugin(item.handle) then
      if cacheFn then cacheFn(item) end
      item.checked = props.markUnloaded
      item.handle = nil
    else
      item.checked = "!" --error
    end
    props.SelectIndex = pos
  until false
end

if _cmdline then
  List({
    Title="Plugins:",
    Id=win.Uuid"EF4EEE0C-8717-4CB8-9A65-AED9095DD26A",
    markUnloaded="✗x",
  }, getPlugins(), getCache())
else --export
  return {
    --fmtTitle=fmtTitle,
    fmtVer=fmtVer,
    fmtChecked=fmtChecked,
    List=List,
  }
end
