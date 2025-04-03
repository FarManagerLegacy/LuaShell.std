-- https://forum.farmanager.com/viewtopic.php?t=12582
-- idea: http://habrahabr.ru/post/229833/
local F = far.Flags
local DlgGuid = win.Uuid"86A0BB8C-5A1E-4BFC-A0A5-01C33A635660"

local ptnTrim = "^%s*(.-)%s*$"
local function lineUp (text)
  local delims = sh.map(sh.splitCL_it(text:match(ptnTrim)))
  return select(2,sh.lineup(delims,"inplace"))
end

local Prompt = "Enter delimeters (space-separated)"
local edtFlags = F.DIF_DEFAULTBUTTON + F.DIF_FOCUS + F.DIF_HISTORY + F.DIF_USELASTHISTORY
local flags = F.FDLG_SMALLDIALOG + F.FDLG_NODRAWSHADOW
local editIdx = 2

local function LineUp_i (init,block)
  block = block or editor.GetSelection()
  local selection = block and {
    BlockType=block.BlockType,
    BlockStartLine=block.StartLine,
    BlockStartPos=1,
    BlockHeight=block.EndLine-block.StartLine+(block.EndPos==0 and 1 or 2),
    BlockWidth=0,
  }
  local initalPos = editor.GetInfo()
  local changed
  local function Undo ()
    if changed then
      changed = false
      editor.UndoRedo(nil, F.EUR_UNDO)
      if selection then editor.Select(nil, selection) end
      editor.SetPosition(nil,initalPos)
    end
  end
  local info = win.GetConsoleScreenBufferInfo()
  local x2 = math.min(80, info.WindowRight+3)
  local y2 = info.WindowBottom-info.WindowTop+1
  far.Dialog(DlgGuid, -1, y2-2, x2, y2, nil, {
  --[[01]] {F.DI_SINGLEBOX,   0, 0,x2-1, 2, 0, 0, 0, 0,Prompt},
  --[[02]] {F.DI_EDIT,        2, 1,x2-3, 1, 0, "LineUpDelimeters", 0, edtFlags, init or ""},
  }, flags, function (hDlg,Msg,Param1,Param2)
    if Msg==F.DN_INITDIALOG then
      changed = lineUp(hDlg:send(F.DM_GETTEXT,editIdx))
    elseif Msg==F.DN_CLOSE then
      if Param1~=editIdx then
        Undo()
      end
    elseif Msg==F.DN_EDITCHANGE then
      Undo()
      changed = lineUp(Param2[10])
    elseif Msg==F.DN_RESIZECONSOLE then
      local X2 = math.min(80,Param2.X)
      hDlg:send(F.DM_RESIZEDIALOG,0,{X=X2, Y=3})
      hDlg:send(F.DM_MOVEDIALOG,1,{X=-1, Y=Param2.Y-2})
      hDlg:send(F.DM_SETITEMPOSITION,1,{Left=0, Top=0, Right=X2-1, Bottom=2})
      hDlg:send(F.DM_SETITEMPOSITION,2,{Left=2, Top=1, Right=X2-3, Bottom=1})
    end
  end)
end

if _cmdline then
  if not Area.Editor then
    print "Utility for interactive line up selected lines by specified delimeters."
    return
  end
  local block = editor.GetSelection()
  if block and block.EndLine==block.StartLine then
    far.Message("At least 2 selected lines expected","Line up selection",nil,"w")
    return
  end
  LineUp_i(nil,block)
else -- export
  return LineUp_i
end
