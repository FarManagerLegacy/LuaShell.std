assert(_cmdline, "meant to be executed directly")
if print==mf.print then
  print = mf.printconsole
end

print "Inspect key presses"
print "Press key ('Esc' to quit)"

local tmpl = "aAcCsNSCE"
local function bitflags (state)
  --local flags = mf.strpad(mf.itoa(state,2),9,"0",1)
  local flags = ""
  for i=1,tmpl:len() do
    local b = bit64.band(2^(i-1), state)==0 and "·" or tmpl:sub(i,i)
    flags = b..flags
  end
  return flags
end

local function fmtChar (char)
  if char==" " then
    char = '" "'
  elseif char=="\0" then
    char = ""
  elseif utf8.byte(char)<=0x1F then -- C0 control codes
    char = "\\"..utf8.byte(char)
  end
  return char
end

local function RecToName (rec)
  local key = far.InputRecordToName(rec)
  local invert = not key
  if invert then
    rec.KeyDown = not rec.KeyDown
    key = far.InputRecordToName(rec) or ""
  end
  return key, invert
end

--https://learn.microsoft.com/en-us/windows/console/console-virtual-terminal-sequences
local ANSI = Far.GetConfig"Interface.VirtualTerminalRendering" or win.GetEnv"ANSICON"
local function c (str, color)
  if ANSI then
    return "\27["..color.."m"..str.."\27[0m"
  end
  return str
end

local last = 0
local function fmtKey (rec)
  local vk,down,count = rec.VirtualKeyCode, rec.KeyDown, rec.RepeatCount
  local name,invert = RecToName(rec)
  local autorepeat
  if down then
    autorepeat = vk==last
    last = vk
  else
    last = 0
  end
  if count~=1 then
    return count.."*"..c(name,"1;33")
  elseif invert==down then
    name = "["..name.."]"
  else
    name = " "..name
  end
  local key
  if down then
    if autorepeat then
      key = " "..c(name,"90")
    else
      key = " "..c(name,"1;37")
    end
  else --up
    key = "↑"..c(name,"33")
  end
  return key
end


local mods = tonumber("11111", 2)
local Esc = far.NameToInputRecord"Esc".VirtualKeyCode

local i = 1
--print "\27[?1049h" --Use Alternate Screen Buffer
print("#","state", tmpl:reverse(), "vk", "sc", "vkname", "",  "char", "  keyname")
local line = ("─"):rep(7)
print(line,line,line..line,line,line,line..line,line,line..line)
local vkeys = win.GetVirtualKeys()
repeat
  local rec
  repeat
    rec = win.ExtractKeyEx() --https://learn.microsoft.com/en-gb/windows/console/key-event-record-str
    win.Sleep(10)
  until rec
  local vk, sc, char, down, state = rec.VirtualKeyCode, rec.VirtualScanCode, rec.UnicodeChar, rec.KeyDown, rec.ControlKeyState
  local vkey = vkeys[vk]
  if vkey:len()<8 then vkey = vkey.."\t" end
  print(i, state, bitflags(state), vk, sc, vkey, fmtChar(char), fmtKey(rec))
  i = i+1
until vk==Esc and bit64.band(state, mods)==0 and not down
--print "\27[?1049l" --Use Main Screen Buffer
