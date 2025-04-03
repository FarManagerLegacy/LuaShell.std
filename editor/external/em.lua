--https://forum.farmanager.com/viewtopic.php?p=154962#p154962
if not Area.Editor then
  if _cmdline=="" then
    print "Expands Emmet's html abbreviations in editor"
    print "To use it place cursor at the line with abbreviation and run 'em'"
    print "See https://docs.emmet.io/cheat-sheet/"
    return
  end
  print((sh.pipeto("emmet -p", _cmdline)))
  return
end

local _,finish,start = editor.GetString(nil,0,3):find"%s*()(%S.*)"
editor.Select(nil, "BTYPE_STREAM", 0, start, assert(finish, "Empty string!")-start+1, 1)
sh.block_process("emmet", function (text) -- "emmet -p"
  local trimmed = text:match("(.-)[\r\n]*$") -- trim eol if text is single line
  return select(2, trimmed:gsub("\n", "\n"))==0 and trimmed or text
end)
