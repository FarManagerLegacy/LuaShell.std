assert(_cmdline, "meant to be executed directly")
local VF = {VF_NONMODAL=1; VF_IMMEDIATERETURN=1}
viewer.Viewer(assert(sh.findScript(...)),nil,nil,nil,nil,nil,VF)


