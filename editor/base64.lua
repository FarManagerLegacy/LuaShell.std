local enc,dec

local success,mime = pcall(require, "mime")
if success then
  enc = mime.b64
  function dec (str)
    return mime.unb64(str..("="):rep(3 - (#str-1) % 4))
  end
else --http://lua-users.org/wiki/BaseSixtyFour
  -- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
  -- licensed under the terms of the LGPL2
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

  function enc (data)
    return ((data:gsub('.', function(x) 
      local r,b='',x:byte()
      for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
      return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
      if (#x < 6) then return '' end
      local c=0
      for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
      return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
  end

  function dec (data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
      if (x == '=') then return '' end
      local r,f='',(b:find(x)-1)
      for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
      return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
      if (#x ~= 8) then return '' end
      local c=0
      for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
      return string.char(c)
    end))
  end
end

local subst = {
  ["-"]="+", ["+"]="-",
  ["_"]="/", ["/"]="_",
}
local function urldec (text)
  return dec(string.gsub(text, "[-_]", subst))
end
local function urlenc (text)
  return string.gsub(enc(text), "[+/]", subst)
end

if _cmdline then
  local text, nosel
  if Area.Editor then
    text = Editor.SelValue
  elseif Area.Dialog and Dlg.ItemType==far.Flags.DI_EDIT then
    text = ""
    if Object.Selected then
      text = Dlg.GetValue():sub(Editor.Sel(0,1), Editor.Sel(0,3))
    end
  else
    print "base64-decode/encode text selection in editor"
    print "Usage: base64 [dec|enc]"
    print "When no arguments given - tries both actions"
    print "If called from another script then returns functions {:encode, :decode, :urlencode, :urldecode}."
    return
  end
  if text=="" then
    text = sh.pick"(eyJ[\\w-.]+)" -- try jwt or json
    if text then
      text = text:match("%.(.-)%.") -- match jwt payload
          or text
    else
      text = sh.pick"([\\w-+/]+=*)" -- try base64url or base64
      if not text then return end
    end
    
    nosel = true
  end

  --todo print or show first?
  local res
  if ...=="enc" then
    res = enc(text)
  else
    res = urldec(text)
    if not res or not res:isvalid() then
      if ... then
        far.Show(win.OemToUtf8(res))
        return
      end
      res = enc(text)
    end
  end

  if nosel or not Area.Editor then
    if res:match"^{" then
      local json = require("dkjson")
      le(json.decode(res))--todo require
    else
      far.Show(res)--todo copy
    end
    return
  end
  mf.postmacro(sh.undo, mf.print, res)
else -- export
  return {
    encode=enc,
    decode=dec,
    urlencode=urlenc,
    urldecode=urldec,
  }
end
