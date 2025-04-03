--https://forum.farmanager.com/viewtopic.php?p=176009#p176009
if print==mf.print then
  print = mf.printconsole
end

local path = win.GetEnv("PATH")

local function activate (venv)
  local dir = venv.."\\Scripts"
  local exist = win.GetFileAttr(dir)
  if exist then
    win.SetEnv("VIRTUAL_ENV", venv)
    win.SetEnv("PATH", dir..";"..path)
    print("venv activated in: "..venv)
    return true
  end
  print "No venv found here"
end

local venv = win.GetEnv("VIRTUAL_ENV") -- support uv
local here = far.ConvertPath("venv")
local exist = win.GetFileAttr(here)

local function deactivate ()
  if not venv then return end
  local scripts = venv.."\\Scripts;"
  local i, j = path:find(scripts,1,true)
  if i then
    path = path:sub(1, i-1)..path:sub(j+1, -1)
    if path:find(scripts,1,true) then
      print "Error: %PATH% includes %VIRTUAL_ENV% more than once"
      return
    end
    win.SetEnv("PATH", path)
    win.SetEnv("VIRTUAL_ENV")
    print("venv deactivated (was in "..venv..")")
  else
    print "Error: %PATH% does not contain %VIRTUAL_ENV%"
    --print(path)
    --print(venv)
  end
end

local function exec (cmdline)
  panel.GetUserScreen()
  win.system(cmdline)
  panel.SetUserScreen()
end

local function newVenv ()
  deactivate()
  --exec(('python -m venv "%s"'):format(here))
  exec(('uv venv "%s"'):format(here)) -- https://github.com/astral-sh/uv
  return activate(here)
end

if ...=="." then -- create new venv
  if exist then
    print("Error: venv already exists")
    return
  end
  newVenv()
elseif ...=="-" then -- deactivate
  if not venv then
    print "No active venv found"
  end
  deactivate()
elseif ... then -- execute cmd with env in cur dir
  if not exist then
    if not newVenv() then return end
  elseif venv~=here then
    deactivate()
    activate(here)
  end
  exec(_cmdline or ...)
elseif exist then
  if venv==here then
    print("venv already activated. Deactivate? [y/N]")
    repeat
      local key = mf.waitkey(0)
      print(key)
      if key:lower()=="y" then deactivate(); break end
    until key=="Enter" or key=="Esc" or key:lower()=="n"
  else
    deactivate()
    activate(here)
  end
elseif not venv then
  activate(here) -- to print err msg
  print "Utility for managing Python virtual environments"
  print "Assumes the virtual environment resides in .\\venv"
  print ""
  print "Usage:"
  print "  venv"
  print "    Activate virtual env in current directory, deactivating previous virtual env"
  print "  venv ."
  print "    Create and activate virtual env in current directory"
  print "  venv command"
  print "    Execute command creating/activating virtual env in current directory"
  print "  venv -"
  print "    Deactivate virtual env"
else
  deactivate()
end
