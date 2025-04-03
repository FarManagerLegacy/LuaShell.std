local filename, ext, dir
if not _cmdline then
  error("meant to be executed directly")
elseif not ... then
  print "cli interface to SearchPathW"
  print "https://learn.microsoft.com/en-us/windows/win32/api/processenv/nf-processenv-searchpathw"
  print "Usage: whereis filename[, ext], dir"
  print "Example:"
  print("  whereis whereis.lua","=>",win.SearchPath(nil,"whereis.lua"))
  return
elseif select('#',...)==3 then
  filename, ext, dir = ...
else
  filename, dir = ...
end
print(win.SearchPath(dir,filename,ext))
