local function plugins_filter_it (filter)
  return coroutine.wrap(function()
    for pi,handle in sh.plugins_it() do
      local passed = filter(pi,handle)
      if passed then
        coroutine.yield(pi,handle,passed)
      end
    end
  end)
end

local function filterPluginsIn (Path,x) --iterate plugins in path
  local path = Path:lower()
  if not path:sub(-1,-1)=="\\" then path = path.."\\" end
  local len = path:len()
  return function (pi)
    local mpath = pi.ModuleName:lower():match"^.+[/\\]"
    if (x=="x")~=(path==mpath:sub(1,len)) then
      return path==mpath and "exact" or true
    end
  end
end

local function filterPluginsName (Name,x) --iterate plugins with name/author/module substr
  local name = Name:lower()
  local function contain (str)
    return str:find(name,1,"plain")
  end
  return function (pi)
    local ModuleFileName = pi.ModuleName:match"[^\\/]+$":match"^(.-)%.":lower()
    local title = pi.GInfo.Title:lower()
    local author = pi.GInfo.Author:lower()
    if (x=="x")==not(contain(title) or contain(author) or contain(ModuleFileName)) then
      return x=="x"
          or (name==title or name==author or name==ModuleFileName) and "exact"
          or true
    end
  end
end
local function ExpandEnv (str) return (str:gsub("%%(.-)%%", win.GetEnv)) end

local function single_it (p,x)
  if x then
    return plugins_filter_it(function (_,handle)
      return p~=handle
    end)
  end
  local pi = far.GetPluginInformation(p)
  return function (_,var)
    if var==nil then return pi, p, "exact" end
    return nil
  end
end
local function no_it ()
  return function() end
end

local function findPlug_it (arg,x)
  if not arg then                                       -- do with all plugs --
    return sh.plugins_it(), "all"
  else
    local path = far.ConvertPath(ExpandEnv(arg),"CPM_FULL")
    local attr = win.GetFileAttr(path)
    if not attr then
      local guid = (arg):match"^{(.+)}$" or arg
      guid = #guid==36 and win.Uuid(guid)
      if guid then                                      -- try guid --
        local p = far.FindPlugin("PFM_GUID",guid)
        if p then
          return single_it(p,x),"guid"
        else
          return no_it(),"guid"
        end
      else                                              -- do with name --
        return plugins_filter_it(filterPluginsName(arg,x)),"name"
      end
    elseif not attr:find"d" then                        -- try module --
      local p = far.FindPlugin("PFM_MODULENAME",path)
      if p then
        return single_it(p,x),"module"
      else
        return no_it(),"module"
      end
    else                                                -- do with path --
      return plugins_filter_it(filterPluginsIn(path,x)),"path"
    end
  end
end

if _cmdline then
  if _cmdline=="" then
    print "Far plugins iterator"
    print "Syntax: sh.findplug_it(str[,x])"
    print "  where str: (title|author|path) substr|guid|module path"
    print "          x: exclude"
    print "CLI usage: findplug_it <substr> [x]"
    print ""
  end
  local arg,x=...
  if arg=="x" then
    x,arg=...
  end

  local F = far.Flags
  local counter = 0
  local plugins, source = findPlug_it(arg,x)
  for pi,_ in plugins do
    local str = ("%s %s  %-25s v%-21s %s"):format(
      band(pi.Flags, F.FPF_ANSI)==0 and " " or "A",
      sh.plugins.fmtChecked(pi) or " ",
      pi.GInfo.Title,
      sh.plugins.fmtVer(pi.GInfo.Version),
      pi.GInfo.Author)
    print(str)
    counter = counter+1
  end
  local tmpl = arg and "[%s: %s]" or "[%s]"
  if x then
    tmpl = tmpl.." - excluded"
  end
  print(("Total: %i plugins matched"):format(counter),
        tmpl:format(source,arg))
else
  return findPlug_it
end
