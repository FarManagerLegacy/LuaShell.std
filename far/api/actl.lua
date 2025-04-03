local cmd = ...
cmd = far.Flags[cmd] and cmd or "ACTL_"..cmd:upper()
nocache = true
return far.AdvControl(cmd, select(2,...))
