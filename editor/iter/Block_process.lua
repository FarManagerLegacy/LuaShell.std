local function ReplBlock (text, keepIndent)
  local li = sh.block_it()()
  editor.SetPosition(nil, 0, li.SelStart)
  local ei = editor.GetInfo()
  local startLine = ei.CurLine
  local startPos = ei.CurPos

   --for case when singleline input processed into multiline output
   if keepIndent then
    local indentStr = li.StringText:match"^%s+" or ""
    --text = text:gsub("([\r\n]+)","%1"..indentStr)
    text = text:gsub("([\r\n]+)([^\r\n])", "%1"..indentStr.."%2")
  end

  local autoindent = Editor.Set(4,0)
  local id = ei.EditorID
  editor.UndoRedo(id, "EUR_BEGIN")
  editor.DeleteBlock(id)
  editor.InsertText(id,text:gsub("\r\n","\n"))
  editor.UndoRedo(id, "EUR_END")
  Editor.Set(4, autoindent) --restore
  ei = editor.GetInfo()
  editor.Select(id, "BTYPE_STREAM", startLine, startPos, ei.CurPos-startPos, ei.CurLine-startLine+1)
end

local function processBlock (cmd,fn)
  if type(cmd)=="function" then
    cmd,fn = nil,cmd
  end
  local text = Editor.SelValue--todo
  if text=="" then
    error "Selection expected"
  end
  local singleline = not text:match("^(.-)[\r\n]*$"):find("\n")
  local ExitCode
  if cmd then
    text,ExitCode = sh.pipeto(cmd,text)
    if ExitCode~=0 then
      far.Message(text:gsub("\r\n", "\n"), cmd, nil, "wl")
      return
    end
  end
  if fn then
    text = fn(text)
  end
  ReplBlock(text, not singleline)
end

if _cmdline then
  if _cmdline=="" or not Area.Editor then
    print "Processes selected block in editor with specified external utility,"
    print "piping it to utility's stdin and then replacing selection"
    print "with returned stdout's content."
    print "Syntax: sh.block_process([cmdline][,fn])"
    return
  end
  processBlock(_cmdline)
else -- export
  return processBlock
end
