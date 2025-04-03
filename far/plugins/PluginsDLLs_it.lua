local ffi = require("ffi")
ffi.cdef[[void GetPluginInfo();]] --Far 1
local function pluginsFiles_it (path)
  local function getStr (wchar)
    local len = 0
    while wchar[len]~=0 do len = len+1 end
    return win.Utf16ToUtf8(ffi.string(wchar, len*2))
  end
  local function getVer (info)
    local ver = {}
    for i,v in ipairs{"Major","Minor","Revision","Build","Stage"} do
      ver[i] = tonumber(info[v])
    end
    return ver
  end
  local files = {}
  far.RecursiveSearch(far.ConvertPath(path), "*.dll", function (_,fullname)
    --if item.FileName=="cygwin1.dll" then return end --prevent crash
    files[#files+1] = fullname
  end,{FRS_RECUR=1,FRS_SCANSYMLINK=1})
  local GInfo = ffi.new("struct GlobalInfo")
  local idx = 0
  return function ()
    while idx<#files do
      idx = idx+1
      local success = pcall(function (info)
        --or alternatively: https://forum.farmanager.com/viewtopic.php?p=123596#p123596
        ffi.load(files[idx]).GetGlobalInfoW(info) --Far 3 only
      end, GInfo)
      if success then
        return {
          GInfo = {
            MinFarVersion=getVer(GInfo.MinFarVersion),
            Version      =getVer(GInfo.Version),
            Guid         =ffi.string(ffi.cast("void*", GInfo.Guid), 16),
            Title        =getStr(GInfo.Title),
            Description  =getStr(GInfo.Description),
            Author       =getStr(GInfo.Author),
          },
          ModuleName = files[idx]
        }
      else
        success = pcall(function ()
          return ffi.load(files[idx]).GetPluginInfo --Far 1
        end)
        if success then
          return {
            Flags = far.Flags.FPF_ANSI,
            ModuleName = files[idx]
          }
        end
      end
    end
    collectgarbage() -- release locked DLL files
    return nil
  end
end

if _cmdline then --testing
  local path = ... or "."

  local counter = 0
  for p in pluginsFiles_it(path) do
    if p.GInfo then
      print(("%-25s v%-21s %s"):
        format(p.GInfo.Title,
               sh.plugins.fmtVer(p.GInfo.Version),
               p.GInfo.Author))
    else
      print(("%-25s [Ansi]"):format(p.ModuleName))
    end
    counter = counter+1
  end
  if counter==0 then
    if not ... then
      print "Far iterator enumerating plugins (*.dll) found in specified path"
      print "Syntax: sh.pluginsDLLs_it(path)"
    end
    print ""
    print("No plugins found", ("[path: %s]"):format(path))
  else
    print ""
    print(("Total: %i plugins found"):format(counter),
          ("[path: %s]"):format(path))
  end
else
  return pluginsFiles_it
end
