local function insert (str, ins, start, finish)
  start = start==0 and 0 or start-1
  finish = (finish or start)+1
  return str:sub(start==0 and 0 or 1, start)..ins..str:sub(finish, finish==0 and 0 or -1)
end
if not _cmdline then -- export
  return insert
else
  print "Insert a substring into a string, optionally replacing a part of it"
  print "Syntax: sh.stringins(str, ins, start[, finish])"
  print "Testing..."
  local sample = "1234"
  local ins = "ab"
  assert(insert(sample,ins, 0)=="ab1234")   --out of range
  assert(insert(sample,ins,-5)=="ab1234")   --out of range
  assert(insert(sample,ins, 1)=="ab1234")
  assert(insert(sample,ins,-4)=="ab1234")
  assert(insert(sample,ins, 2)=="1ab234")
  assert(insert(sample,ins,-3)=="1ab234")
  assert(insert(sample,ins, 3)=="12ab34")
  assert(insert(sample,ins,-2)=="12ab34")
  assert(insert(sample,ins, 4)=="123ab4")
  assert(insert(sample,ins,-1)=="123ab4")
  assert(insert(sample,ins, 5)=="1234ab")   --out of range
  assert(insert(sample,ins, 0, 1)=="ab234") --out of range
  assert(insert(sample,ins,-5,-4)=="ab234") --out of range
  assert(insert(sample,ins, 1, 2)=="ab34")
  assert(insert(sample,ins,-4,-3)=="ab34")
  assert(insert(sample,ins, 2, 3)=="1ab4")
  assert(insert(sample,ins,-3,-2)=="1ab4")
  assert(insert(sample,ins, 3, 4)=="12ab")
  assert(insert(sample,ins,-2,-1)=="12ab")
  assert(insert(sample,ins, 4, 5)=="123ab") --out of range
  print "Passed"
end
