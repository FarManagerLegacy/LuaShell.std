-- originally based on macro "Подстановка текста из редактора в строку ввода диалога" by Shmuel
-- https://forum.farmanager.com/viewtopic.php?f=15&t=10112

-- Goal: pick some text from current editor line into dialog input field
-- What is picked:
--   (a) if some text in the line is selected - that text is picked
--   (b) else the word under cursor,
--       else the nearest word in the forward direction,
--       else the nearest word in the backward direction.
-- If the text in the input field is equal to (a) then (b) is picked and vice versa.

-- SETTINGS
local def = regex.new("(\\w+)")
-- END OF SETTINGS

local F = far.Flags

local function GetTextFromLine (str,pos,pattern)
  pos = pos or 1
  if pattern and pattern.len then
    pattern = regex.new(pattern)
  end
  pattern = pattern or def
  assert(pattern:bracketscount()>=2,"regex must contain parentheses")
  local last,offset,match = 0
  repeat
    offset,last,match = pattern:find(str, last+1)
    if not offset or offset>pos then
      return nil, pos
    elseif last>pos then
      return match, offset, last
    elseif last<offset then
      last = offset
    end
  until false
end

local function GetSelection (line)
  local sel = line.SelStart>=1 and
              line.SelStart<=line.StringLength and -- forbid BeyondEOL selection
              line.SelEnd>0 and -- forbid multiline selection
              line.StringText:sub(line.SelStart, line.SelEnd)
  return sel~="" and sel
end

local function toggle (curtext,sel,word)
  if not sel or curtext == sel and word then
    return word
  end
  return sel
end

local function GetTextFromEditor ()
  local dinfo = far.AdvControl(F.ACTL_GETWINDOWINFO, nil)
  local nfocus = dinfo.Id:send(F.DM_GETFOCUS)
  local ditem = dinfo.Id:send(F.DM_GETDLGITEM, nfocus)
  if ditem and (ditem[1]==F.DI_EDIT or ditem[1]==F.DI_FIXEDIT or ditem[1]==F.DI_COMBOBOX) then
    local line = editor.GetString()
    if not line then return nil end
    local ei = editor.GetInfo()
    local sel = ei.BlockStartLine==ei.CurLine and GetSelection(line)
    local word = GetTextFromLine(line.StringText, ei.CurPos, def)
    local text = toggle(ditem[10], sel, word)
    if text then dinfo.Id:send(F.DM_SETTEXT, nfocus, text) end
  end
end

if Macro then
  Macro {
    description="Pick word under editor cursor";
    area="Dialog"; key="CtrlShiftW";
    id="47ED5740-8907-493C-820D-8770F029DCFB";
    action=GetTextFromEditor;
  }
  return
end

if not _cmdline then -- export
  return {
    GetSelection=GetSelection,
    GetTextFromLine=GetTextFromLine,
  }
else
  if Area.Dialog then
    GetTextFromEditor()
  else
    print "Picks word under editor cursor"
    print "Meant to be called from dialog's input box."
    print "When called from another script - exports its internal functions"
  end
end
