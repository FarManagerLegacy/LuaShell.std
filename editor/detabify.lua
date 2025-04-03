local function detabify (str, tabsize) --https://forum.farmanager.com/viewtopic.php?f=15&t=9209
  return string.gsub(str, "(.-)\t", function(s)
    return s..(" "):rep(tabsize - s:len()%tabsize)
  end)
end

if not _cmdline then -- export
  return detabify
else
  if not Area.Editor then
    print "Detabify lines in current editor selection (or current line)"
    print "If called from another script then returns function."
    print "Syntax: sh.detabify(str,tabsize)"
    return
  end
  local ei = editor.GetInfo()
  editor.UndoRedo(ei.EditorID, "EUR_BEGIN")
  for str,eol,n in sh.SelLines_it.lua{info=ei, ifnosel="curline"} do
    str,replaced = detabify(str, ei.TabSize)
    if replaced~=0 then
      editor.SetString(ei.EditorID, n, str ,eol)
    end
  end
  editor.UndoRedo(ei.EditorID, "EUR_END")
end
