if _cmdline=="" then
  print "List files in current directory"
  print "Usage: ggg filemask"
  return
end

sh"filesmenu"(_cmdline, nil, nil, "FRS_NONE")