local function range_it (_start, _end, _step)
  if _step and _start~=_end and (_start<_end)~=(_step>0) then
    error("invalid 'step' value")
  end
  if not _end then
    _end = _start
    _start = 1
  end
  _step = _step or _start<=_end and 1 or -1
  local i = _start
  return function ()
    i = _start
    _start = _start+_step
    if (i<_end)==(_step>0) or i==_end then
      return i
    end
  end
end

if _cmdline=="" then
  print "Iterates over a range of integers"
  print "Syntax: range_it([start], end, [step])"
  print "Examples:"
  print ("range_it(5,10)", "=>",
        sh.dump(sh.map(range_it(5,10))))
  print ("range_it(10)", "=>",
        sh.dump(sh.map(range_it(10))))
  print ("range_it(2,10,2)", "=>",
        sh.dump(sh.map(range_it(2,10,2))))
  print ("range_it(10,2,-2)", "=>",
        sh.dump(sh.map(range_it(10,2,-2))))
elseif _cmdline then
  sh.each(range_it(sh.mapargs(tonumber, ...)), print)
else
  return range_it
end
