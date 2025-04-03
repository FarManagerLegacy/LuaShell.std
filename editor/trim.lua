local function trim ()
  local counter = 0
  for text,eol,n in sh.lines_it() do
    text,repl=text:gsub("%s+$", "")
    if repl>0 then
      editor.SetString(nil,n,text,eol)
      counter = counter+1
    end
  end
  if counter>0 then mf.beep() end
  return counter
end

if _cmdline then
  if not Area.Editor then
    print "Trim lines trailing spaces in editor"
    print "If called from another script then returns function."
    return
  end
  sh.toast(("%s line(s) trimmed"):format(sh.undo(trim)), "trim", 1500)
else -- export
  return trim
end
