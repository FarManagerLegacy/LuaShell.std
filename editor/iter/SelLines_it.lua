local function sellines_it (opt)
  opt = opt or {}
  local ei = opt.info or editor.GetInfo(opt and opt.id)
  if not ei then error(opt.id and "invalid editor id specified" or "editor not found",2) end
  local id,cur = ei.EditorID, ei.BlockStartLine --copy here to let gc of `ei`
  local curline,nosel = opt.ifnosel=="curline"
  if ei.BlockType==far.Flags.BTYPE_NONE then
    if not opt.ifnosel then return function() end end
    nosel = true
    if curline then cur = 0 end
  end
  return function ()
    local line = editor.GetString(id,cur,0)
    if line and (nosel or line.SelStart~=0 and line.SelEnd~=0) then
      if curline then nosel = false end
      cur = cur + 1
      return line.StringText, line.StringEOL, line.StringNumber
    end
  end
end

if not _cmdline then -- export
  return sellines_it
else --testing
  if Area.Editor then
    print "testing sellines_it on selection:"
    for line,eol,n in sellines_it{ifnosel="curline"} do
      print(n..":", line, (eol:gsub("\n","\\n"):gsub("\r","\\r")))
    end
  else
    print("Selected lines iterator for editor")
    print [[
Usage:
  for line,eol,n in sh.sellines_it(opt) do ... end

opt: optional table with fields:
  id:      integer,  EditorID
  info:    table,    EditorInfo,
  ifnosel: string    Action if no selection detected
    nil (default),   - no action
    "all",           - iterate over all lines
    "curline",       - iterate once with current line
]]
  end
end
