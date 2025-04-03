local EPOCH_DIFF = 11644473600 --number of seconds from 1 Jan. 1601 00:00 to 1 Jan 1970 00:00 UTC

--https://forum.farmanager.com/viewtopic.php?p=174178#p174178

-- sample usage: local unixtime = FileToUnixTime(filetime, far.FileTimeResolution()==1)
local function FileToUnixTime (filetime, lowres)
  local resolution = lowres and 1000 or 10000000
  return filetime / resolution - EPOCH_DIFF
end

-- sample usage: local filetime = UnixToFileTime(unixtime, far.FileTimeResolution()==1)
local function UnixToFileTime (unixtime, lowres)
  local resolution = lowres and 1000 or bit64.new(10000000)
  return (unixtime + EPOCH_DIFF) * resolution
end

--https://forum.farmanager.com/viewtopic.php?p=174812#p174812
local function byte2int (str)
  local r = 0
  for i = 1, #str do
    r = bit.bor(bit.lshift(r, 8), string.byte(str, -i))
  end
  return r
end
local function petime (exe)
  local f, err = io.open(exe, "rb")
  if not f then return nil, err end
  f:seek("set", 0)
  if f:read(2)~="MZ" then f:close(); return nil, "Not MZ" end
  f:seek("set", 60)
  f:seek("set", byte2int(f:read(4)))
  if f:read(2) ~= "PE" then f:close(); return nil, "Not PE" end
  f:seek("cur", 6)
  local unixtime = byte2int(f:read(4));
  f:close();
  return unixtime
end

if _cmdline then
  local format = "%c"
  local arg = ...
  local fix
  if arg=="fix" then
    fix = true
    arg = select(2, ...)
  end
  local file, fullname, info
  if arg then
    file = arg
    fullname = far.ConvertPath(file)
    info = win.GetFileTimes(fullname)
  else --curfile
    info = panel.GetSelectedPanelItem(nil,1,1)
    file = info.FileName
    fullname = far.ConvertPath(file)
    if fullname==_filename then
      print [[
Usage: filetime [fix] [filename]
Prints LastWriteTime, and for *.exe - PE time
- If fix specified then sets LastWriteTime=PE time
- When no filename specified - file under cursor used
]]
    end
  end
  print(fullname)
  if not info then
    print "Error: file not found"
    return
  end
  local ftime = info.LastWriteTime
  print("LastWriteTime:", os.date(format, FileToUnixTime(ftime))) --sh.filetime.toUnix
  if file:match"%.exe$" then
    local unixtime, err = petime(fullname) --sh.filetime.petime
    if err then print("Error:", err); return end
    print("PE time:", os.date(format, unixtime) or unixtime)
    if fix then
      local timedate = UnixToFileTime(unixtime) --sh.filetime.fromUnix
      assert(win.SetFileTimes(fullname, {LastWriteTime=timedate}))
      print("LastWriteTime: fixed")
    end
  end
else --export
  return {
    fromUnix=UnixToFileTime,
    toUnix=FileToUnixTime,
    petime=petime,
  }
end
