local guid = win.Uuid(win.Uuid()):upper()
if _cmdline then
  if Area.Editor then
    local line = editor.GetString(nil,0,3)
    local _, SelStart, SelEnd = sh.pick("([0-9a-fA-F-]{36})")
    editor.SetString(nil, 0, sh.stringins(line,guid,SelStart,SelEnd))
    editor.Select(nil, "BTYPE_STREAM", 0, SelStart, 36, 1)
  else
    if Area.Shell or Area.QView or Area.Info or Area.Tree then
      print "Generates GUID and copies it to Clipboard"
      print "In Editor: inserts GUID /replacing existent if any/"
      print(guid)
    end
    far.CopyToClipboard(guid)
  end
end
return guid
