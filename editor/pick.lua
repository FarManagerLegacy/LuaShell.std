local F = far.Flags
local function pick (pattern)
  if Area.Editor then
    local line = editor.GetString()
    local ei = editor.GetInfo()
    local sel = ei.BlockStartLine==ei.CurLine and sh.pickFromEditor.GetSelection(line)
    if sel then
      return sel, line.SelStart, line.SelEnd
    end
    return sh.pickFromEditor.GetTextFromLine(line.StringText, ei.CurPos, pattern)

  elseif Area.Dialog and Dlg.ItemType==F.DI_EDIT then
    local str = Dlg.GetValue()
    if Object.Selected then
      local SelStart, SelEnd = Editor.Sel(0,1), Editor.Sel(0,3)
      return str:sub(SelStart, SelEnd), SelStart, SelEnd, str
    else
      local match, SelStart, SelEnd = sh.pickFromEditor.GetTextFromLine(str, Object.CurPos, pattern)
      return match, SelStart, SelEnd, str
    end

  else
    error"Wrong area"
  end
end

if not _cmdline then -- export
  return pick
elseif Area.Dialog then
  --alias to std/editor/pickFromEditor.lua
  return sh("pickFromEditor",{_cmdline=_cmdline})()
else
  print "If called from another script - exports function"
  print "Syntax: sh.pick([pattern])"
  print "When executed directly - calls 'pickFromEditor' script"
end
