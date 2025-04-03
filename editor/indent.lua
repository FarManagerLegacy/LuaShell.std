local def = " "
local function indent (dir,symb,force)
  local ei = editor.GetInfo()
  editor.UndoRedo(ei.EditorID, "EUR_BEGIN")
  for text,eol,n in sh.sellines_it{info=ei, ifnosel="curline"} do
    if text~="" or force then
      symb = symb or text:match("^%s") or def
      if not dir then
        local start,fin = text:find(symb,1,"plain")
        if start==1 then
          editor.SetString(ei.EditorID, n, text:sub(fin+1,-1), eol)
        end
      else
        editor.SetString(ei.EditorID, n, symb..text, eol)
      end
    end
  end
  editor.UndoRedo(ei.EditorId, "EUR_END")
  editor.Redraw(ei.EditorId)
end

if _cmdline then
  if not Area.Editor then
    print "Un/Indents lines in current editor selection (or current line)"
    print "Usage: indent [un] [symbol] [force]"
    print "  symbol: default is existing or space"
    print "  force: process empty lines"
    print "If called from another script then returns function."
    print "Syntax: sh.indent(direction,symbol) /false dir. means unindent/"
    return
  end
  local symb,force = ...
  local unindent
  if symb=="un" then
    unindent,symb,force = ...
  end
  if symb=="force" then
    force,symb = true
  end
  indent(not unindent, symb, force)
else -- export
  return indent
end
