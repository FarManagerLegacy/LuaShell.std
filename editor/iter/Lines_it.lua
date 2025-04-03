local function lines_it (...)
  local ei, from,to = ...
  if not ei or not type(ei)=="table" then
    ei = editor.GetInfo()
    if not ei then error("meant to be called in editor", 2) end
    from,to = ...
  end
  local eid,line = ei.EditorID, from or 1
  return function()
    if to and to<line then return end
    local text,eol = editor.GetString(eid,line,3)
    if text then
      line = line + 1
      return text,eol,line-1
    end
  end
end

if not _cmdline then -- export
  return lines_it

else --testing
  if Area.Editor then
    local from, to
    if _cmdline~="" then from, to = sh.mapargs(tonumber,...) end
    print "testing lines_it on editor's text:"
    for line,eol,n in lines_it(from, to) do
      print(n..":", line, (eol:gsub("\n","\\n"):gsub("\r","\\r")))
    end
  else
    print "Lines iterator for editor"
    print "Usage: for line,eol,n in sh.lines_it([ei],[from,to]) do ... end"
  end
end
