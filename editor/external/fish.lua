local function fish (number_, type_)
  local cmd = ([[curl -s "https://fish-text.ru/get?format=html&type=%s&number=%s"]]):format(type_ or "", number_ or "")
  local file = io.popen(cmd)
  local text = file:read("*a")
  file:close()
  return text
    :gsub("<p>(.-)</p>", "%1\n")
    :gsub("<h1>(.-)</h1>", "%1\n")
end

local function wrap (str, limit)
  limit = limit or 80
  return str:gsub("[^\n]+", function (para)
    local start = 1
    return para:gsub("()(%S+)()", function (a,s,b)
      if b-start>limit then
        local hyphen = s:find"%-"
        if hyphen and a+hyphen+1<=start+limit then
          start = a+hyphen+1
          return s:sub(1,hyphen).."\n"..s:sub(hyphen+1)
        end
        start = a
        return "\n"..s
      end
    end).."\n"
  end)
end

local default = { width=80 }
local M = setmetatable({ default=default }, {
  __call=function(self,count,opt)
    local element = opt and opt.element or self.default.element
    local text = fish(count, element)
    local width = element~="title" and self.default.width
    if opt and opt.width~=nil then width = opt.width end
    return width and width>0 and wrap(text, width)
        or text
  end
})

local function insert (count,opt)
  mf.postmacro(mf.print, M(count,opt)) -- mf.print(require"fish"(count,opt))
end

if MenuItem then MenuItem {
  description="РыбаТекст";
  menu="Plugins"; area="Editor"; text="РыбаТекст";
  guid="C0D90EAA-4ABF-4888-BEB2-E2087B4ECD10";
  action=function()
    insert()
  end;
} elseif _cmdline then -- LuaShell cmdline
  if Area.Editor then
    insert(sh.eval(_cmdline))
  elseif _cmdline=="" then
    print "fish-text generator"
    print "Syntax: fish-text [count][,opt]"
    print "  count: number of elements to generate"
    print "  opt: table, with following possible fields:"
    print "  - element: string, type of element to generate"
    print "    'sentence'|'paragraph'|'title'"
    print "  - width: number, position where to wrap lines"
    print "When called from another script then returns function."
    print "Syntax: sh.fish([count][,opt])"
  else
    print(M(sh.eval(_cmdline)))
  end
else -- module
  return M
end
