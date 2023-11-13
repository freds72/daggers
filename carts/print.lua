-- print helper
function arizona_print(s,x,y,sel)
	sel=sel or 0
	-- shadow
	local pos=?s,x,y+1,1
	for j=0,6 do
		clip(0,y+j,128,1)
		?s,x,y,sget(32+sel,j)
	end
	clip()
	return pos
end
