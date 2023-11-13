-- game states
function next_state(fn,...)	 
	-- to allow call from exec
	fn=_ENV[fn] or fn
	local u,d,i=fn(...)
	-- ensure update/draw pair is consistent
	_update_state=function()
		-- init function (if any)
		if(i) i()
		-- 
		_update_state,_draw=u,d
		-- actually run the update
		u()
	end
end