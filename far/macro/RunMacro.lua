local path = win.GetEnv("FARPROFILE")..[[\Macros\utils\3rd-party\macros\]]

local function isActive (self)
  return self.area:match"Common" or self.area:match("%f[%w]"..Area.Current.."%f[%W]")
end

local mt = {
  __call = function (self, ...)
    if self.area then
      local key = self.key and self.key:match"w+" --primitive guess
      --just primitive check, and flags not checked
      local ok = isActive(self)
      if ok and self.condition then
        ok = self.condition(key,self)
      end
      if ok then
        mmode(1, self.flags and self.flags:match"EnableOutput" and 0 or 1)
        self.action(self)
        return
      end

    elseif self.menu then
      --just primitive processing, Plugins menu only
      local ok = not self.Area or isActive(self)
      if ok and type(self.text)~="string" then
        ok = self.text("Plugins", Area.Current)
      end
      if ok then
        self.action(far.Flags.OPEN_PLUGINSMENU)
        return
      end

    elseif self.prefixes then
      self.action(self.prefixes:match"[^:]+":lower(), ...) --just pick first prefix
      return

    else
      error "Unsupported script type"
    end

    far.Message("Wrong area or macro condition check not passed", _filename, nil, "w")
  end
}

local function read (name,filter)
  local parentEnv = getfenv(2)
  if parentEnv==_G then --xpcall + tailcall
    local name,f = debug.getlocal(3,1)
    assert(name=="func")
    parentEnv = getfenv(f)
  end
  if not parentEnv._cmdline then
    error("meant to be executed directly", 2)
  end
  local function ExpandEnv (str) return (str:gsub("%%(.-)%%", win.GetEnv)) end
  name = ExpandEnv(name)
  if not name:match":" then
    name = path..name
  end
  name = (function () --guess ext
    local exts = {""}
    sh._shared.options.pathext:gsub("%.%w+", function (ext) table.insert(exts, ext) end)
    for _,ext in ipairs(exts) do
      local filename = name..ext
      local attr = win.GetFileAttr(filename)
      if attr and not attr:find"d" then
        return filename
      end
    end
    return name
  end)()

  local macros = setmetatable({}, {
    __call = function (self,...)
      if #self==0 then error "no macro found" end
      return self[1](...)
    end
  })
  local function dummy () end
  local function collect (m)
    if filter and not filter(m) then return end
    macros[#macros+1] = setmetatable(m, mt)
  end
  local env = {print=mf.print}
  for _,k in ipairs {"CommandLine", "ContentColumns", "Event", "Macro", "MenuItem", "PanelModule"} do
    env[k] = collect
    env["No"..k] = dummy
  end
  sh(name, env)(name)
  return macros
end

if _cmdline=="" then
  print "Utility to run macro from specified file"
  print "Syntax: sh.runmacro(filename,filterFn)"
  print "Returns table of enumerated macros, see examples for more info."
elseif _cmdline then
  read((...))()
  --todo pick from list
else -- export
  return read
end
