-- requires string.lua

-- does nothing
function nop() end
_ENV["//"]=nop
function set(k,v,env)
	(_ENV[env] or _ENV)[k]=v
end

-- helper to execute a call (usually from a split string)
function exec(code)
	split2d(code,function(fn,...)
		_ENV[fn](...)
	end)
end
