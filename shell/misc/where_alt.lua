local function where(name)
  return select(2,sh(name))
end
if not _cmdline then
  return where
elseif _cmdline=="" then
  print(_filename:match"[^\\/]+$","search script in path")
else
  print(where(...))
end
