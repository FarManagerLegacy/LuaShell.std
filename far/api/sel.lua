nocache = true
return table.concat(sh.map(sh.block_it{mode="str",ifnosel="all"}),"\n")

--[[ get selection or all
local id = ei.EditorId
local sel = ei.BlockType~=F.BTYPE_NONE
local text = {}
for l=ei.BlockStartLine,ei.TotalLines do
  local li = editor.GetString(id,l,0)
  if sel then
    if not li.SelStart then break end
    text[#text+1] = li.StringText:sub(li.SelStart,li.SelEnd)
  else
    text[#text+1] = li.StringText
  end
end
local text = table.concat(text,"\n")
--]]