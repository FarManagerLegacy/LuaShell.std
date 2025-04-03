local function SelIter ()
  local ei = editor.GetInfo()
  if ei.BlockType==far.Flags.BTYPE_NONE then return function() end end
  local id,cur = ei.EditorID,ei.BlockStartLine --copy here to let gc of `ei`
  return function ()
    local line = editor.GetString(id,cur, 0)
    if line and line.SelStart~=0 and line.SelEnd~=0 then
      cur = cur + 1
      return line.StringText,line.StringEOL,line.StringNumber
    end
  end
end

local function lineup (delims,text)
  local max = {}
  for i=1,#delims do
    max[i] = 0
    if delims[i]=="" then delims[i] = " " end
  end
  delims[0] = ""

  local lines = {}
  local iter = text and text~="inplace" and text:gmatch("([^\r\n]*)\r?\n?")
                                         or SelIter()
  for line,eol,n in iter do
    local stops,lens = {},{}
    stops[0] = 1
    for i,delim in ipairs(delims) do
      stops[i] = line:find(delim,stops[i-1]+delims[i-1]:len(),"plain")
      if not stops[i] then break end
      lens[i] = stops[i]-stops[i-1]-delims[i-1]:len()
      max[i] = math.max(max[i],lens[i])
    end
    lines[#lines+1] = {
      str=line,
      eol=eol,
      n=n,
      stops=stops,
      lens=lens,
    }
  end

  local out = {}
  for i,line in ipairs(lines) do
    local str = ""
    line.stops[#line.stops+1] = "last"
    for j,s in ipairs(line.stops) do
      local start = line.stops[j-1]
      if s=="last" then
        str = str..line.str:sub(start,line.str:len())
        break
      end
      local sub = line.str:sub(start, s-1)
      sub = sub..(" "):rep(max[j]-line.lens[j])
      str = str..sub
    end
    out[i] = str
  end

  if text=="inplace" then
    editor.UndoRedo(nil, "EUR_BEGIN")
    for i,line in ipairs(lines) do
      editor.SetString(nil, line.n, out[i], line.eol)
    end
    editor.UndoRedo(nil, "EUR_END")
  end
  return out
end

if Macro then
  Macro { description="";
    area="Editor"; key="CtrlShiftD";
    id="7A72E88E-4F05-4F95-B538-E760E6FE6C6B";
    condition=function()
      return Editor.SelValue~=""
    end;
    action=function()
      local str = far.InputBox(
        "56FEC4D9-F18E-4649-9F8E-8957D10E48C1",
        "Lineup selection",
        "Enter delimeters (space-separated)",
        "LineUpDelimeters")
      if not str then return end
      local delims = {};
      for d in str:gmatch("%S+") do
        if d=='""' or d=="''" then d = " " end
        delims[#delims+1]=d
      end
      lineup(delims,"inplace")
    end;
  }
elseif _cmdline=="" then
  print "Utility to line up selected lines by delimeters."
  print "Usage: lineup <delimeters>"
  print "Being called from another script - returns function."
  print "Syntax: lines = sh.lineup(delimeters,text)"
  print "- delimeters: table"
  print "- text: string"
  print "if `text` is omitted or equal to 'inplace' then editor's selected lines are processed"
  print "(either 'inplace', or just return resulted lines table instead)"
elseif _cmdline then
  lineup({...},"inplace")
else -- export
  return lineup
end
