if _cmdline=="" then
  print "List files from current directory (recursively)"
  print "Usage: gg filemask"
  return
end

sh"filesmenu"(_cmdline)