pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--# notice! #
--run this cart with
--root_path set to project root

---convert address to coords
--@param num {number}
--	address to convert
--@return {integer}
--	x-coordinate,
--	rounded to nearest integer
--@return {integer}
--	y-coordinate,
--	rounded to nearest integer
function addr_to_wh(addr)
	return
		addr < 64 and (64 - addr) * 2 or 128,
		ceil(addr / 64)
end

---print integer in hexadecimal notation
function tohex(n)
	return sub(tostr(n, true), 1, 6)
end

-- px9 data compression v9
-- by zep
--[[
    ██▒ how to use ▒██

    1. compress your data

        px9_comp(source_x, source_y,
            width, height,
            destination_memory_addr,
            read_function)

        e.g. to compress the whole
        spritesheet to the map:

        px9_comp(0,0,128,128,
            0x2000, sget)
]]
-- px9 compress

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function
	px9_comp(x0,y0,w,h,dest,vget)

	local dest0=dest
	local bit=1
	local byte=0

	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
		return i
--]]

--[[ 8 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return i
			end
		end
--]]
	end

	local cache,cache_bits=0,0
	function putbit(bval)
	 cache=cache<<1|bval
	 cache_bits+=1
		if cache_bits==8 then
			poke(dest,cache)
			dest+=1
			cache,cache_bits=0,0
		end
	end

	function putval(val, bits)
		for i=bits-1,0,-1 do
			putbit(val>>i&1)
		end
	end

	function putnum(val)
		local bits = 0
		repeat
			bits += 1
			local mx=(1<<bits)-1
			local vv=min(val,mx)
			putval(vv,bits)
			val -= vv
		until vv<mx
	end


	-- first_used

	local el={}
	local found={}
	local highest=0
	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			c=vget(x,y)
			if not found[c] then
				found[c]=true
				add(el,c)
				highest=max(highest,c)
			end
		end
	end

	-- header

	local bits=1
	while highest >= 1<<bits do
		bits+=1
	end

	putnum(w-1)
	putnum(h-1)
	putnum(bits-1)
	putnum(#el-1)
	for i=1,#el do
		putval(el[i],bits)
	end


	-- data

	local pr={} -- predictions

	local dat={}

	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			local v=vget(x,y)

			local a=y>y0 and vget(x,y-1) or 0

			-- create vlist if needed
			local l=pr[a] or {unpack(el)}
			pr[a]=l

			-- add to vlist
			add(dat,vlist_val(l,v))

			-- and to running list
			vlist_val(el, v)
		end
	end

	-- write
	-- store bit-0 as runtime len
	-- start of each run

	local nopredict
	local pos=1

	while pos <= #dat do
		-- count length
		local pos0=pos

		if nopredict then
			while dat[pos]!=1 and pos<=#dat do
				pos+=1
			end
		else
			while dat[pos]==1 and pos<=#dat do
				pos+=1
			end
		end

		local splen = pos-pos0
		putnum(splen-1)

		if nopredict then
			-- values will all be >= 2
			while pos0 < pos do
				putnum(dat[pos0]-2)
				pos0+=1
			end
		end

		nopredict=not nopredict
	end

	if cache_bits>0 then
		-- flush
		poke(dest,cache<<8-cache_bits)
		dest+=1
	end

	return dest-dest0
end

-- px9 data compression v9
-- by zep
--[[
    ██▒ how to use ▒██

    2. decompress

        px9_decomp(dest_x, dest_y,
            source_memory_addr,
            read_function,
            write_function)

        e.g. to decompress from map
        memory space back to the
        screen:

        px8_decomp(0,0,0x2000,
            pget,pset)
]]
-- px9 decompress

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function
	px9_decomp(x0,y0,src,vget,vset)

	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
--]]

--[[ 7 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return
			end
		end
--]]
	end

	-- bit cache is between 8 and
	-- 15 bits long with the next
	-- bits in these positions:
	--   0b0000.12345678...
	-- (1 is the next bit in the
	--   stream, 2 is the next bit
	--   after that, etc.
	--  0 is a literal zero)
	local cache,cache_bits=0,0
	function getval(bits)
		if cache_bits<8 then
			-- cache next 8 bits
			cache_bits+=8
			cache+=@src>>cache_bits
			src+=1
		end

		-- shift requested bits up
		-- into the integer slots
		cache<<=bits
		local val=cache&0xffff
		-- remove the integer bits
		cache^^=val
		cache_bits-=bits
		return val
	end

	-- get number plus n
	function gnp(n)
		local bits=0
		repeat
			bits+=1
			local vv=getval(bits)
			n+=vv
		until vv<(1<<bits)-1
		return n
	end

	-- header

	local
		w,h_1,      -- w,h-1
		eb,el,pr,
		x,y,
		splen,
		predict
		=
		gnp"1",gnp"0",
		gnp"1",{},{},
		0,0,
		0
		--,nil

	for i=1,gnp"1" do
		add(el,getval(eb))
	end
	for y=y0,y0+h_1 do
		for x=x0,x0+w-1 do
			splen-=1

			if(splen<1) then
				splen,predict=gnp"1",not predict
			end

			local a=y>y0 and vget(x,y-1) or 0

			-- create vlist if needed
			local l=pr[a] or {unpack(el)}
			pr[a]=l

			-- grab index from stream
			-- iff predicted, always 1

			local v=l[predict and 1 or gnp"2"]

			-- update predictions
			vlist_val(l, v)
			vlist_val(el, v)

			-- set
			vset(x,y,v)
		end
	end
end

--------------
--main program
--------------
--offset from payload destination
offset = 0

paths = {
	manifest = "./carts/titleaudio",
	output = "../carts/freds72_daggers_title.p8",
}

payloads = {
	{
		id = "musicii",
		addr = 0x3100,
		ulen = 0x1200,
	},
	{
		id = "musiciii",
		addr = 0x3100,
		ulen = 0x1200,
	},
	{
		id = "daggercollect",
		addr = 0x31f8,
		ulen = 0x0448,
	},
	{
		id = "noisedata",
		addr = 0,
		ulen = 0x0aa4,
	},
	{
		id = "chatter",
		addr = 0x3420,
		ulen = 0x0550,
	},
}

--init manifest
printh("--title.p8 audio payloads:", paths.manifest, true)
printh("audio = {", paths.manifest, true)

--compress and record assets
for payload in all(payloads) do
	--get audio asset
	memset(0x6000, 0, 0x2000)
	reload(0x6000, payload.addr, payload.ulen, "./" .. payload.id .. ".p8")

	--compress asset
	local w, h = addr_to_wh(payload.ulen)
	local clen = px9_comp(0, 0, w, h, 0x8000 + offset, pget)

	assert(offset + clen <= 0x2300, "payload is too large!")

	--print payload data to paths.manifest
	printh("\t" .. payload.id .. " = {", paths.manifest)
	printh("\t\taddr = " .. tohex(0x2000 + offset) .. ",", paths.manifest)
	printh("\t\t--clen = " .. tohex(clen) .. ",", paths.manifest)
	printh("\t\t--data = nil,", paths.manifest)
	printh("\t\tulen = " .. tohex(payload.ulen) .. ",", paths.manifest)
	printh("\t" .. "},", paths.manifest)

	--update offset
	offset += clen
end

--close manifest
printh("}\n", paths.manifest)

--write payload to title
cstore(0x2000, 0x8000, offset, paths.output)

--print results
msg = "payload: " .. sub(tostr(offset, true), 1, 6) .. " bytes\n\ndon't forget to\nupdate memory.txt!"

cls()
print(msg)
printh("\n" .. msg)

--load next cart
if #stat(6) > 0 then
	load(stat(6), nil, "stop")
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
