if _cmdline then
  print "Editor Undo wrapper, puts callback action into single EUR_BEGIN..EUR_END"
  print "Syntax:"
  print "  sh.undo(EditorID, callback, ...)"
  print "  sh.undo(callback, ...)"
else -- export
  return function (...)
    local first, id, callback = 3, ...
    if type(id)=="function" then
      first, id, callback = 2, editor.GetInfo().EditorID, ...
    end
    editor.UndoRedo(id, "EUR_BEGIN")
    return (function (...)
      editor.UndoRedo(id, "EUR_END")
      return ...
    end)(callback(select(first, ...)))
  end
end
