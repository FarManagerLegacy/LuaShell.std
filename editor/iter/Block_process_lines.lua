local function block_process_lines (fn,opt)
  opt = opt or {}
  local ei = opt.info or editor.GetInfo(opt.id)
  if not ei then error(opt.id and "invalid editor id specified" or "meant to be called in editor", 2) end
  opt.info = ei
  opt.mode = nil
  editor.UndoRedo(ei.EditorID, "EUR_BEGIN")
  local nosel = opt.all or ei.BlockType==far.Flags.BTYPE_NONE
  for li in sh.block_it(opt) do
    local str = li.StringText
    local sel = nosel and str or str:sub(li.SelStart, li.SelEnd)
    local ret = fn(sel,li)
    if ret and ret~=sel then
      str = nosel and ret or
        str:sub(1, li.SelStart-1)..
        ret..
        (li.SelEnd~=-1 and str:sub(li.SelEnd+1) or "")
      editor.SetString(ei.EditorID, li.StringNumber, str, li.StringEOL)
    end
  end
  editor.UndoRedo(ei.EditorID, "EUR_END")
end

if _cmdline then
  print "Process selected text line by line passing selection to specified function"
  print "and then replacing selection with returned text"
  print "Syntax: sh.block_process_lines(fn,opt)"
  print "(opt: see block_it.lua)"
else -- export
  return block_process_lines
end
