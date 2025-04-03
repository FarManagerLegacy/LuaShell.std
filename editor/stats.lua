assert(_cmdline, "meant to be executed directly")
if not Area.Editor then
  print(_filename:match"[^\\/]+$", "Show editor text stats")
  return
end

local F = far.Flags
local words,chars,chars_sp = 0,0,0
for str in sh.block_it{ifnosel="all", mode="str"} do
  words = words + select(2, str:gsub("%w+", "%1"))
  chars = chars + select(2, str:gsub("%S", "%1"))
  chars_sp = chars_sp + str:len()
end
far.Message(([[
Words        │ %s
Characters   │ %s
incl. spaces │ %s]]):format(words, chars, chars_sp), "Text statistics", "")
mf.waitkey()

--[[
https://support.microsoft.com/en-us/office/show-word-count-3c9e6a11-a04d-43b4-977c-563a0e0d5da3
Pages
Words
Characters (no spaces)
Characters (with spaces)
Paragraphs
Lines
--]]