local function pick (opts)
  opts = opts or {}
  local function match (line,indent)
    if line:len()==0 then
      return not opts.excludeEmpty
    end
    if not opts.ignoreIndent then
      local len = indent:len()
      if line:sub(1,len)~=indent then
        return false 
      end
      if opts.excludeNested and line:sub(len+1, len+1):match("%s")  then
        return false
      end
    end
    if opts.match and not opts.match(line) then
      return false
    end
    return true
  end

  local ei = opts.info or editor.GetInfo()
  local id = ei.EditorID
  local cur = ei.CurLine
  local first
  repeat --look backward
    local line = editor.GetString(id,cur,3)
    indent = indent or line:match("^(%s*)")
    local matched = match(line,indent)
    first =  matched and cur or first
    cur = cur-1
  until not matched or cur==0
  if not first then return false end

  local last = ei.CurLine
  cur = ei.CurLine+1
  repeat --look forward
    local line = editor.GetString(id,cur,3)
    local matched = line and match(line,indent)
    last =  matched and cur or last
    cur = cur+1
  until not matched or cur==0
  if not last or last==first then return false end

  return {
    BlockType=far.Flags.BTYPE_STREAM,
    BlockStartLine=first,
    BlockStartPos=1,
    BlockHeight=last-first+2,
    BlockWidth=0,
  }
end

if _cmdline then
  if not Area.Editor then
    print "Pick text block in editor based on indentation"
    print "Usage: block_pick"
    print "Being called from another script - returns function"
    print "Syntax: selection = sh.block_pick([opts])"
    print "  opts: table with optional fields"
    print "  - match        : function; every line should pass"
    print "  - excludeEmpty : boolean; stop on empty lines"
    print "  - excludeNested: boolean; stop on deeper indentation"
    print "  - ignoreIndent : boolean; take into account match only"
    print "  - info         : table; editor info"
    return
  end
  local sel = pick()
  if sel then editor.Select(nil,sel); editor.Redraw() end
else -- export
  return pick
end
