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

---load px9-compressed audio to ram
--@param id string
--	audio table key
--@param dest integer
--	address to decompress to
function audio_load(id, dest)
	poke4(dest or 0x3100, unpack(audio[id].data))
end

---get 4-byte ram values as table
--gets an arbitrary length
--of data from ram
--as a table suitable for
--using with poke4(unpack())
--
--@param addr integer
--	starting ram address
--
--@param len integer
--	length in bytes to get
--
--@returns table
--	table of 4-byte words
function ram_to_tbl(addr, len)
	local tbl = {}

	for i = 0, len - 1, 4 do
		add(tbl, $(addr + i))
	end

	return tbl
end

