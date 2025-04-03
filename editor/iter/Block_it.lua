local BTYPE_NONE = far.Flags.BTYPE_NONE
local function block_it (opt)
  opt = opt or {}
  local ei = opt.info or editor.GetInfo(opt.id)
  if not ei then error(opt.id and "invalid editor id specified" or "meant to be called in editor", 2) end
  local sel = {
    id = ei.EditorID, --copy here to let gc of `ei`
    selection = ei.BlockType~=BTYPE_NONE and not opt.all,
    nLines = ei.TotalLines,
    str = opt.mode=="str",
    str_full = opt.mode=="str:full",
  }
  if sel.selection or opt.all or opt.ifnosel=="all" then
    sel.line = opt.all and 1 or ei.BlockStartLine
  elseif opt.ifnosel=="curline" then
    sel.nLines = ei.CurLine
    sel.line = ei.CurLine
  else
    return function() end
  end
  return function ()
    if sel.line<=sel.nLines then
      local line = editor.GetString(sel.id, sel.line, 0)
      if line and (not sel.selection or (line.SelStart~=0 and opt.last or line.SelEnd~=0)) then
        sel.line = sel.line + 1
        if sel.str then
          local str = line.StringText
          if sel.selection and not (line.SelStart==1 and (line.SelEnd==-1 or line.SelEnd==line.StringLength)) then
            str = str:sub(line.SelStart, line.SelEnd)
          end
          return str, line.SelEnd==-1 and line.StringEOL or "", line
        elseif sel.str_full then
          return line.StringText, line.SelEnd==-1 and line.StringEOL or "", line.StringNumber
        else
          return line
        end
      end
    end
  end
end

if not _cmdline then -- export
  return block_it
else --testing
  if Area.Editor then
    local ei = editor.GetInfo()
    print "testing block_it on selection/or curline:"
    if _cmdline=="" then
      for li in block_it{info=ei, ifnosel="curline"} do
        print(sh.dump(li))
      end
    else
      for str, eol, line in block_it{info=ei, ifnosel="curline", mode="str"} do
        print(line..":", str, (eol:gsub("\n","\\n"):gsub("\r","\\r")))
      end
    end

  else
    print("Block iterator for editor")
    print [[
Usage:
  for li in sh.block_it(opt) do ... end          -- returns line info (see editor.GetString)
 or
  for text,eol,li in sh.block_it(opt) do ... end -- opt.mode=="str"

opt: optional table with fields:
  id:      integer,  EditorID
  info:    table,    EditorInfo,
  all:     boolean,  `true` to ignore selection and iterate over all lines
  ifnosel: string    Action if no selection detected
    nil (default),   - no action
    "all",           - iterate over all lines
    "curline",       - iterate once with current line
  last:    boolean,  `true` to include last line even if it has no visible selection (.SelStart==1 .SelEnd==0)
  mode:    string,   defines type of returned values
    nil (default),   - EditorGetString: table
    "str",           - str,eol,li:      string, string, table
    "str:full",      - str,n:           string, number
]]
  end
end
