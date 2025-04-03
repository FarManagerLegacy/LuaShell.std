--todo dialog

local function userFn (file)
  return #file.FileName>20 -- sample
end

local counter = 0
sh.selfiles_process(function(file)
  if skip_dirs or skip_files then
    local isDir = file.FileAttributes:find"d"
    if skip_dirs and isDir or skip_files and not isDir then
      return
    end
  end
  counter = counter+1
  return userFn(file)
end)
print(counter.." files processed")
