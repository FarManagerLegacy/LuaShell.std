--from https://github.com/mirven/underscore.lua/blob/master/lib/underscore.lua#L328
local function is_equal(o1, o2, ignore_mt)
	local ty1 = type(o1)
	local ty2 = type(o2)
	if ty1 ~= ty2 then return false end

	-- non-table types can be directly compared
	if ty1 ~= 'table' then return o1 == o2 end

	-- as well as tables which have the metamethod __eq
	local mt = getmetatable(o1)
	if not ignore_mt and mt and mt.__eq then return o1 == o2 end

	for k1,v1 in pairs(o1) do
		local v2 = o2[k1]
		if v2 == nil or not is_equal(v1,v2, ignore_mt) then return false end
	end
	for k2,v2 in pairs(o2) do
		local v1 = o1[k2]
		if v1 == nil then return false end
	end
	return true
end

if _cmdline=="" then
  print("Performs an optimized deep comparison between the two objects,"
      .."to determine if they should be considered equal."
      .." By default it uses the _eql metamethod if it is present.")
  print "Syntax: is_equal(o1,o2,[ignore_mt])"
  print "Examples:"
  print ("  is_equal({1,2,3}, {1,2,3})", "=>",
        is_equal({1,2,3}, {1,2,3}))
  print ("  is_equal({a=1,b=2}, {a=1,b=2})", "=>",
        is_equal({a=1,b=2}, {a=1,b=2}))
  print ("  is_equal({a=1,b=2}, {a=2,b=3})", "=>",
        is_equal({a=1,b=2}, {a=2,b=3}))

elseif _cmdline then
  print(is_equal(sh.eval(_cmdline)))
else
  return is_equal
end
