-- radix sort
-- credits: james edge (@jimi)
function rsort(data)	
	local len,buffer1,buffer2,idx=#data, data, {}, {}

	-- radix shift (multiplied by 128 to get more precision)
	for shift=-7,-2,5 do
		-- faster than for each/zeroing count array
		memset(0x4300,0,32)
		for i,b in pairs(buffer1) do
			local c=0x4300+((b.key>>shift)&31)
			poke(c,@c+1)
			idx[i]=c
		end
				
		-- shifting array
		local c0=@0x4300
		for mem=0x4301,0x431f do
			local c1=@mem+c0
			poke(mem,c1)
			c0=c1
		end

		for i=len,1,-1 do
		local k=idx[i]
			local c=@k
			buffer2[c] = buffer1[i]
			poke(k,c-1)
		end

		buffer1, buffer2 = buffer2, buffer1
	end
	return buffer2
end
