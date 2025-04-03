local function enc (text)
  --sel = string.gsub(sel, " ", "+")
  --sel = string.gsub(sel, "\r?\n", "\r\n")

  --https://datatracker.ietf.org/doc/html/rfc3986#section-2.3
  local keep = {
    ":/?#[%]@",    -- gen-delims
    "!$&'()*+,;=", -- sub-delims
    "%w%-._~",     -- unreserved
    --" ", -- extra
  }
  return string.gsub(text, ("[^%s]"):format(table.concat(keep)), function (str)
    return string.format("%%%02X", string.byte(str))
  end)
end

local function dec (str)
  return str:gsub('%%(%x%x)', function(hex)
    return string.char(tonumber(hex, 16))
  end)--:gsub("+", " ")
end

if _cmdline then
  if not Area.Editor then
    print "uri-decode/encode text selection in editor"
    print "Usage: uri [dec|enc]"
    print "When no arguments given - tries both actions"
    print "If called from another script then returns functions {:enc, :dec}."
    return
  end
  local text = Editor.SelValue
  if text=="" then return end

  local res = ...~="enc" and dec(text)
  if not res or res==text then
    if ...=="dec" then return end
    res = enc(text)
  end

  mf.postmacro(sh.undo, mf.print, res)
else -- export
  return {
    enc=enc,
    dec=dec,
  }
end
