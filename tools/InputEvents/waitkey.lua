assert(_cmdline, "meant to be executed directly")
print "Inspect FAR shortcuts names"
print "Press key ('Esc' to quit)"
local i = 0
repeat
  local key = mf.waitkey()
  local mBut = Mouse.Button
  i = i+1
  print(i,key,mBut==0 and "" or mBut)
until key=="Esc"

