-- adapted from https://github.com/mbpowers/lorem-nvim/
-- License: MIT

-- https://forum.farmanager.com/viewtopic.php?t=13230
local source = _filename or debug.getinfo(1,"S").source:match"^@(.+)"
local path = source:match"^.+[\\/]"

local M,mt

local function lorem (opt)
  opt = opt and opt~=M.defaults and setmetatable(opt, mt) or M.defaults
  local words = opt.words
  if opt.wordspath then
    words = {}
    local filename = opt.wordspath:match"[\\/]" and opt.wordspath or path..opt.wordspath
    local f = assert(io.open(filename))
    local txt = f:read("*a")
    f:close()
    txt:gsub("%w+",function(w) words[#words+1] = w:lower() end)
    table.sort(words)
    for i=#words-1,1,-1 do
      if words[i]==words[i+1] then table.remove(words,i) end
    end
    if rawget(M,"words")==nil then M.words = words end
  elseif type(words)=="string" then
    words = {}
    opt.words:gsub("%w+",function(w) words[#words+1] = w end)
    if rawget(M,"words")==nil then M.words = words end
  end

  -- Set seed based on time, generate delays randomly between min and max
  if opt.seed then math.randomseed(opt.seed) end

  local commaDelay = math.random(opt.commamin, opt.commamax)
  local periodDelay = math.random(opt.periodmin, opt.periodmax)
  local paragraphDelay = math.random(opt.paragraphmin, opt.paragraphmax)

  local punct
  return function ()
    local word = words[math.random(1, #words)]

    -- Capitalize first letter of a sentence.
    if not punct or punct == "." then
      word = word:gsub("^%l", string.upper)
    end

    punct = ""
    local paragraph
    -- Set punct/paragarph based on punctuation delays.
    if periodDelay == 0 then
      punct = "."
      periodDelay = math.random(opt.periodmin, opt.periodmax)
      if paragraphDelay == 0 then
        paragraphDelay = math.random(opt.paragraphmin, opt.paragraphmax)
        paragraph = true
      end
      paragraphDelay = paragraphDelay - 1
    elseif commaDelay == 0 then
      punct = ","; commaDelay = math.random(opt.commamin, opt.commamax)
    end
    commaDelay = commaDelay - 1; periodDelay = periodDelay - 1
    return word..punct, paragraph
  end
end

local defaults = {
  -- see https://github.com/mbpowers/lorem-nvim/#configuration
  commamin    =5,
  commamax    =11,
  periodmin   =2, --6,
  periodmax   =17,--14,
  paragraphmin=3, --4 ,
  paragraphmax=3, --10,
  --wordspath="englishwords", -- can be arbitrary text file (only unique words processed)

  -- extra:
  paragraphend="\n",

  textend="\n",

  count=25, -- for use when count not specified

  --seed=far.FarClock(), -- "seed" for the pseudo-random generator: equal seeds produce equal sequences of numbers.

  words=[[
a ac accumsan adipiscing aliquam aliquet amet ante arcu at augue bibendum
blandit commodo condimentum consectetur consequat convallis curabitur
cursus dapibus diam dictum dictumst dignissim dolor donec dui duis
efficitur egestas eget eleifend elementum elit enim erat eros est et etiam
eu euismod ex facilisi facilisis fames faucibus felis fermentum feugiat
finibus fringilla fusce gravida habitant habitasse hac hendrerit iaculis id
imperdiet in integer interdum ipsum justo lacinia lacus laoreet lectus leo
libero ligula lobortis lorem luctus maecenas magna malesuada massa mattis
mauris maximus metus mi molestie mollis morbi nam nec neque netus nibh nisi
non nulla nullam nunc odio orci ornare pellentesque pharetra phasellus
placerat platea porta porttitor posuere potenti praesent pretium primis
proin pulvinar purus quam quis quisque rhoncus risus sagittis sapien
scelerisque sed sem semper senectus sit sodales sollicitudin suscipit
suspendisse tellus tempor tempus tincidunt tortor tristique turpis ultrices
ultricies urna ut varius vehicula vel velit venenatis vestibulum vitae
vivamus viverra volutpat vulputate
]], -- alternative to `wordspath`; can also be table of words

  -- format options:
  width=80,
  align=true,
}

local function align (line, width)
  local spaces = width-line:len()
  local holes = spaces and select(2,line:gsub(" ", " "))
  if not holes then return line end
  local n = math.fmod(spaces,holes)
  local each = (spaces-n)/holes
  return line:gsub(" ", function()
    local len = each
    if n>0 then len,n = len+1,n-1 end
    return (" "):rep(len+1)
  end)
end

local function format (iter, count, opt)
  local lines,line,nPara = {},"",0
  for word,paragraph in iter(opt) do
    local space = paragraph and opt.paragraphend or " "
    if line:len() + word:len() > opt.width then
      assert(line~="", "width is not enough")
      lines[#lines+1] = opt.align and align(line:match"^(.-)%s?$", opt.width) or line
      line = word..space
    else
      line = line..word..space
    end
    if paragraph then
      lines[#lines+1],line,nPara = line,"",nPara+1
    end
    if #lines+nPara>=count then
      if not paragraph then
        lines[#lines] = lines[#lines]:match"^(.-)%p?%s?$"
          .."."
          ..opt.paragraphend
      end
      break
    end
  end
  return table.concat(lines,"\n")..opt.textend
end

M = {
  defaults=defaults,
  singleline={
    paragraphmin=-1,
    paragraphmax=-1,
    paragraphend="",
    textend="",
    width=false,
  },
  iter=lorem,
}
mt = { __index=function(_,k)
  return M.defaults[k]
end}
setmetatable(M, {
  __call=function(_, count, opt)
    if type(count)=="table" or type(count)=="string" then
      count,opt = nil,count
    end
    if type(opt)=="string" then opt = M[opt] end -- presets: default, singleline
    opt = opt and opt~=M.defaults and setmetatable(opt, mt) or M.defaults
    count = count or opt.count
    if opt.width and opt.width~=0 then
      return format(lorem, count, opt)
    end
    local lines,line = {},""
    for word,paragraph in lorem(opt) do
      local space = paragraph and opt.paragraphend or " "
      line = line..word..space
      if paragraph then
        lines[#lines+1],line = line,""
        if #lines==count then break end
      end
    end
    return table.concat(lines,"\n")..opt.textend
  end
})

local function insert (count,opt)
  mf.postmacro(mf.print, M(count,opt)) -- mf.print(require"lorem"(count,opt))
end

if MenuItem then MenuItem {
  description="Lorem ipsum generator";
  menu="Plugins"; area="Editor"; text="Lorem ipsum";
  guid="B37764B4-5784-41E7-8668-20C448184DAF";
  action=function()
    insert()
  end;
} elseif _cmdline then -- LuaShell cmdline
  if Area.Editor then
    insert(sh.eval(_cmdline))
  elseif _cmdline=="" then
    print "Lorem ipsum generator"
    print "Syntax: lorem [count][,opt]"
    print "  count: number of words to generate"
    print "  opt: table, see `defaults` in source"
    print "When called from another script then returns function."
    print "Syntax: sh.lorem([count][,opt])"
    print "Note: sh.lorem is a table with fields `defaults`, `iter`, etc."
    print "      See the sources for usage hints"
  else
    print(M(sh.eval(_cmdline)))
  end
else -- module
  return M
end
