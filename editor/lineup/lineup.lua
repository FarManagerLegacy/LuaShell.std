--https://forum.farmanager.com/viewtopic.php?t=12582
local function SelIter ()
  local ei = editor.GetInfo()
  if ei.BlockType==far.Flags.BTYPE_NONE then return function() end end
  local id,cur = ei.EditorID,ei.BlockStartLine --copy here to let gc of `ei`
  return function ()
    local line = editor.GetString(id,cur, 0)
    if line and line.SelStart~=0 and line.SelEnd~=0 then
      cur = cur + 1
      return line.StringText, line.StringEOL, line.StringNumber
    end
  end
end

local function align (str,width,atype)
  width = width or 0
  local addLen = width-str:len()
  if atype=="l" or atype=="" or not atype then
    return str..(" "):rep(addLen)
  elseif atype=="r" then
    return (" "):rep(addLen)..str
  else
    local half = math.floor(addLen/2)
    return (" "):rep(half)..str..(" "):rep(addLen-half)
  end
end
local ptnTrim = "^%s*(.-)%s*$"
local function lineup (delims,text)
  local max,alignment,spaced,lspaced = {},{},{},{}
  for i=1,#delims do
    max[i],spaced[i],lspaced[i] = 0,true,true
    local al,del = delims[i]:match"%%([rlc])(.*)"
    if al then
      delims[i] = del
      alignment[i] = al
    end
    if delims[i]=="" then delims[i] = " " end
  end
  delims.eol = #delims
  if delims[#delims]~="eol" then
    delims.eol = delims.eol+1 -- add implicit eol
  end
  delims[delims.eol] = ""
  max[delims.eol] = 0
  local unmatched = -1

  local lines = {}
  local iter
  if text and text~="inplace" then
    iter = text:gmatch("([^\r\n]*)\r?\n?")
  else
    local ei = editor.GetInfo()
    if sh and ei.BlockType==far.Flags.BTYPE_NONE then
      local sel = sh.block_pick{excludeEmpty=true, excludeNested=true, info=ei, match=function (line)
        local prev = 0
        for i,delim in ipairs(delims) do
          if i==delim.eol then
            break
          else
            local is_space = delim==" "
            local start,fin = line:find(is_space and " +" or delim,
                                        prev+1,
                                        not is_space and "plain")
            if not start then return false end
            prev = fin
          end
        end
        return true
      end}
      if sel then editor.Select(ei.EditorID, sel) end
    end
    iter = SelIter()
  end
  for line,eol,n in iter do
    local substrs = {}
    local start,fin
    local prev = 0
    for i,delim in ipairs(delims) do
      if i==delims.eol then
        substrs[i] = line:sub(prev+1,-1)
      else
        local is_space = delim==" "
        start,fin = line:find(is_space and " +" or delim,
                              prev+1,
                              not is_space and "plain")
        if not start then
          substrs[unmatched] = line:sub(prev+1,-1):match("^%s*(.-)$") --ltrim
          break
        end
        spaced[i] = spaced[i] and not delim:match(" +") and line:sub(fin+1, fin+1)==" "
        lspaced[i] = lspaced[i] and not delim:match(" +") and line:sub(start-1, start-1)==" "
        substrs[i] = line:sub(prev+1,start-1)
      end

      if i==1 then --preserve indent
        local indent = line:match("^%s*")
        if not delims[0] or indent:len()<delims[0]:len() then
          delims[0] = indent
        end
      end
      substrs[i] = substrs[i]:match(ptnTrim)
      max[i] = math.max(max[i],substrs[i]:len())
      prev = fin
    end
    lines[#lines+1] = {eol=eol, n=n, substrs=substrs}
  end
  if delims[0] and delims[1]:match("%s") then --prevent adding spaces to indent
    local len = delims[1]:len()
    if delims[0]:sub(-len,-1)==delims[1] then
      delims[0] = delims[0]:sub(1,-len-1)
    end
  end
  for i,delim in ipairs(delims) do
    if spaced[i] and not delim:match"%s$" then
      delims[i] = delims[i].." "
    end
    if lspaced[i] and not delim:match"^%s" then
      delims[i] = " "..delims[i]
    end
  end

  local out = {}
  for i,line in ipairs(lines) do
    local str = ""
    for j,_ in ipairs(delims) do
      if not line.substrs[j] then
        str = str..(delims[j-1] or "")..line.substrs[unmatched]
        break
      end
      local width = max[j]
      if j==delims.eol and not alignment[j] then
        width = 0 --prevent trailing padding
      end
      str = str
        ..(delims[j-1] or "")
        ..align(line.substrs[j], width, alignment[j])
    end
    out[i] = str
    line.changed = str~=line
  end
  local changed = false
  if text=="inplace" then
    editor.UndoRedo(nil, "EUR_BEGIN")
    for i,line in ipairs(lines) do
      if line.changed then
        editor.SetString(nil, line.n, out[i], line.eol)
        changed = true
      end
    end
    editor.UndoRedo(nil, "EUR_END")
  end
  return out,changed
end

if Macro then
  Macro {
    description="Line up selected lines by specified delimeters";
    area="Editor"; key="CtrlShiftD";
    id="7A72E88E-4F05-4F95-B538-E760E6FE6C6B";
    condition=function()
      return Editor.SelValue~=""
    end;
    action=function()
      local str = far.InputBox(
        "56FEC4D9-F18E-4649-9F8E-8957D10E48C1",
        "Line up selection",
        "Enter delimeters (space-separated)",
        "LineUpDelimeters")
      if not str then return end
      local delims = {};
      for d in str:match(ptnTrim):gmatch("%S+") do
        if d=='""' or d=="''" then d = " " end
        delims[#delims+1]=d
      end
      lineup(delims,"inplace")
    end;
  }
elseif _cmdline=="" then
  if Area.Editor then
    sh("lineup_i",{_cmdline=""})()
  else
    print "Utility to line up selected lines by specified delimeters."
    print "Usage: lineup <delimeters>"
    print "To alternate alignment mode precede delimiter with %r|%l|%c modifiers."
    print 'To refer end of line use "eol" delimeter.'
    print ""
    print "Being called from another script - returns function."
    print "Syntax: lines = sh.lineup(delimeters,text)"
    print "- delimeters: table"
    print "- text: string"
    print "if `text` is omitted or equal to 'inplace' then editor's selected lines are processed"
    print "(either 'inplace', or just return resulted lines table instead)"
  end
elseif _cmdline then
  return lineup({...},"inplace")
else -- export
  return lineup
end
--!!enhance expand tabs
