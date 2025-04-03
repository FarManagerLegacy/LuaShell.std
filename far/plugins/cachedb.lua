local sqlite3 = require("lsqlite3")
local ffi = require("ffi")
local file = ("%s\\plugincache.%s.db"):format(win.GetEnv"FARLOCALPROFILE", jit.arch)

local function getVer (info)
  local ver = {}
  for i,v in ipairs{"Major","Minor","Revision","Build","Stage"} do
    ver[i] = tonumber(info[v])
  end
  return ver
end

local function guessAnsi (info)
  if not info.GInfo.Guid then return end
  if string.sub(info.GInfo.Guid, 1, 8)==("\0"):rep(8) then -- heuristics
    info.Flags = info.Flags + far.Flags.FPF_ANSI
  end
end

local function getCache ()
  local db = assert(sqlite3.open(file, sqlite3.SQLITE_OPEN_READONLY))
  local items,ids = {},{}
  local query = "SELECT * FROM "
  for id,ModuleName in db:urows(query.." cachename") do
    local GInfo, PInfo = {}, {}
    local item = {GInfo=GInfo, PInfo=PInfo, ModuleName=ModuleName, Flags=0, id=id}
    items[ModuleName] = item
    ids[id] = item
  end
  local tmpl = "%s: '%s' id not in cachename"
  local function process (tbl, key1, key2, fn)
    for cid,col2 in db:urows(query..tbl) do
      if ids[cid] then
        ids[cid][key1][key2] = fn and fn(col2) or col2
      else
        print(tmpl:format(tbl,cid))
      end
    end
  end
  process("authors", "GInfo", "Author")
  process("descriptions", "GInfo", "Description")
  process("guids", "GInfo", "Guid", win.Uuid)
  process("pluginversions", "GInfo", "Version", function (version)
    return getVer(ffi.cast("struct VersionInfo*", version))
  end)
  process("prefixes", "PInfo", "CommandPrefix")
  process("preload", "PInfo", "Flags", function (num)
    return num==0 and 0 or far.Flags.PF_PRELOAD
  end)
  process ("titles", "GInfo", "Title")
  assert(db:close()==sqlite3.OK)
  for _,item in pairs(items) do guessAnsi(item) end
  return items
end

local function cleanCache (id)
  local db = assert(sqlite3.open(file, sqlite3.SQLITE_OPEN_READWRITE))
  db:exec("BEGIN;")
  local success = true
  local function assertPrn (tbl, res, errmsg)
    if res~=sqlite3.OK then
      success = false
      print(tbl, errmsg)
    end
  end
  for tbl in db:urows("SELECT name FROM sqlite_master WHERE type='table' AND name!='cachename';") do
    local query = ("DELETE FROM %s WHERE cid = %d"):format(tbl, id)
    assertPrn(tbl, db:exec(query))
  end
  local query = ("DELETE FROM %s WHERE id = %d"):format("cachename", id)
  assertPrn("cachename", db:exec(query))
  db:exec(success and "COMMIT;" or "ROLLBACK;")
  assert(db:close()==sqlite3.OK)
  return success
end

-------------------------------------------
-- the rest is for testing purposes only --

local function dumpCacheTables ()
  local db = assert(sqlite3.open(file, sqlite3.SQLITE_OPEN_READONLY))
  local query = "SELECT * FROM %s WHERE cid=%d;"
  for row in db:nrows("SELECT * FROM cachename") do
    if not win.GetFileAttr(row.name) then
      print("File not exist:", row.id, row.name)
    else
      local title
      for _,str in db:urows(query:format("titles", row.id)) do
        title = str
      end
      if title then
        print("Access OK:", row.id, row.name)
      else
        print("Access locked:", row.id, row.name)
      end
    end
  end
  assert(db:close()==sqlite3.OK)
end

local function getCacheItems (cid)
  local db = assert(sqlite3.open(file, sqlite3.SQLITE_OPEN_READONLY))
  local data = {}
  for tbl in db:urows("SELECT name FROM sqlite_master WHERE type='table';") do
    local item = {}
    data[tbl] = item
    local query = ("SELECT * FROM %s WHERE %s = %d"):format(tbl, tbl=="cachename" and "id" or "cid", cid)
    for row in db:nrows(query) do
      for k,v in pairs(row) do
        if k=="cid" then
          --skip
        elseif item[k] then
          local t = item[k]
          if type(t)~="table" then
            t = {item[k]}
            item[k] = t
          end
          t[#t+1] = v
        else
          item[k] = v
        end
      end
    end
  end
  assert(db:close()==sqlite3.OK)
  return data
end

local function getCacheItem (path)
  local db = assert(sqlite3.open(file, sqlite3.SQLITE_OPEN_READONLY))
  local cid
  local query = "SELECT * FROM %s WHERE name='%s';"
  for id in db:urows(query:format("cachename", path)) do
    cid = id
  end
  if not cid then return end
  local GInfo, PInfo = {}, {}
  local item = {GInfo=GInfo, PInfo=PInfo, ModuleName=path, Flags=0, id=cid}
  query = "SELECT * FROM %s WHERE cid=%d;"
  for _,str in db:urows(query:format("authors", cid)) do
    GInfo.Author = str
  end
  for _,str in db:urows(query:format("descriptions", cid)) do
    GInfo.Description = str
  end
  for _,str in db:urows(query:format("guids", cid)) do
    GInfo.Guid = win.Uuid(str)
  end
  for _,version in db:urows(query:format("pluginversions", cid)) do
    local v = ffi.cast("struct VersionInfo*", version)
    GInfo.Version = getVer(v)
  end
  for _,str in db:urows(query:format("prefixes", cid)) do
    PInfo.CommandPrefix = str
  end
  for _,num in db:urows(query:format("preload", cid)) do
    PInfo.Flags = num==0 and 0 or far.Flags.PF_PRELOAD
  end
  for _,str in db:urows(query:format("titles", cid)) do
    GInfo.Title = str
  end
  assert(db:close()==sqlite3.OK)
  guessAnsi(item)
  return item
end

if _cmdline=="" then
  dumpCacheTables()
elseif _cmdline then
  local cid = tonumber(..., 10)
  if cid then
    print(sh.dump(getCacheItems(cid)))
  else
    local path = far.ConvertPath(_cmdline)
    local item = getCacheItem(path)
    print(item and sh.dump(item) or "Cache item not found for: "..path)
  end
else --export
  return {
    getCache=getCache,
    cleanCache=cleanCache,
  }
end
