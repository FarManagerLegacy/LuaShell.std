local function lineUpPipe ()
  local sel = editor.GetSelection()
  local block
  if not sel then
    block = sh.block_pick{excludeEmpty=true, ignoreIndent=true, match=function (line)
      return line:match("|")
    end}
    if block then
      editor.Select(nil,block)
    else
      far.Message("Table not found","Line up pipe table")
      return
    end
  end
  local start = sel and sel.StartLine or block.BlockStartLine
  local header_row = editor.GetString(nil, start+1, 3)
  local delims = {}
  header_row:gsub("|",function () delims[#delims+1] = "|" end)
  delims[#delims+1] = "eol"
  local ptnTrim = "^%s*(.-)%s*$"
  if header_row:match("^[-|%s:]+$") then
    local i = header_row:match("^%s*|") and 2 or 1
    for sep in header_row:gmatch("[^|]+") do
      sep = sep:match(ptnTrim)
      local symb = sep:match("^%-%-+:$") and "r"
                or sep:match("^:%-+:") and "c"
                or (sep:match("^:%-%-+$") or sep:match("^%-+$")) and false
      if symb then
        delims[i] = "%"..symb..delims[i]
      elseif symb==nil then
        sh.toast("Unable to parse header row")
      end
      i = i+1
    end
  end

  sh.lineup(delims,"inplace")
end

if _cmdline then
  if not Area.Editor then
    print "Utility to lineup markdown pipe table"
    print "https://docs.github.com/en/github/writing-on-github/working-with-advanced-formatting/organizing-information-with-tables"
    print "Usage: lineup_pipe"
    return
  end
  lineUpPipe()
else -- export
  return lineUpPipe
end

--[[
| Header 1 | Another header here | This is a long header |
| --- | --: | :-: |
| Some data | Some more data | data |
| data | Some long data here | more data |
--]]

--[[
 Header 1  | Another header here | This is a long header
 --- | --: | :-:
 Some data | Some more data | data
 data | Some long data here | more data
--]]

--!! enhance \| (escape pipes)
