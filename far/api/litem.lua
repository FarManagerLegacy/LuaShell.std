local idx = sh.hDlg:send"DM_GETFOCUS"
local lidx = sh.hDlg:send("DM_LISTGETCURPOS",idx)
nocache = true
return sh.hDlg:send("DM_LISTGETITEM",idx,lidx.SelectPos)
