pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--devil daggers sfx
--by ridgek

--# notice! #
--run this cart with
--root_path set to project root

--0x4300-0x431f: sfx effect bytes (title.lua)
--0x4324-0x47a3: note high bytes (title.lua)
--0x47a4-0x48a3: sfx effect bytes damp 0 (title.lua)
--0x48a4-0x49a3: sfx effect bytes damp 1 (title.lua)
--0x49a4-0x4aa3: sfx effect bytes damp 2 (title.lua)
--0x4aa4-0x4ba3: note high bytes attn 0 (title.lua)
--0x4ba4-0x4ca3: note high bytes attn 1 (title.lua)
--0x4ca4-0x4da3: note high bytes attn 2 (title.lua)

--get assets
reload(0x3100, 0x3100, 0x1300, "./sfx.p8")
reload(0x4300, 0x0000, 36 + (32 * 36) + 0x300 + 0x300, "./noisedata.p8")

function _init()
	--test distance
	dist = 0
	--test sfx
	noise = 8

	--benchmark stats
	avg = 0
	cpu = 0
	stats = {}
end

function _update()
	--##############
	--# pre-flight #
	--##############
	--get input
	if (btnp(0)) noise = max(8, noise - 1)
	if (btnp(1)) noise = min(63, noise + 1)
	if (btnp(2)) dist = min(4, dist + 1)
	if (btnp(3)) dist = max(0, dist - 1)

	--simulate _chatter_ranges offsets
	local offsets = {
		attn = 0x4aa4 + ceil(dist / 2) * 256,
		damp = 0x47a4 + dist \ 2 * 256
	}

	--init cpu benchmark
	cpu = stat(1)

	--########
	--# main #
	--########
	---noise playback
	local in_progress

	for i = 0, 3 do
		local cur_sfx = stat(46 + i)

		if cur_sfx == noise then
			in_progress = true
		end

		if cur_sfx ~= -1 then
			--poke effect byte
			--offset: 0x4300 + (cur_sfx - 8)
			poke(0x3240 + cur_sfx * 68, @(offsets.damp + @(0x42f8 + cur_sfx)))

			--poke note bytes
			--@todo set i to stat(50-53)
			for i = stat(50 + i), 31 do
					poke(0x3201 + cur_sfx * 68 + i * 2, @(offsets.attn + @(0x4324 + (cur_sfx - 8) * 32 + i)))
			end
		end
	end

	if not in_progress then
		sfx(noise)
	end

	--#########
	--# stats #
	--#########
	cpu = stat(1) - cpu

	add(stats, cpu)

	if #stats > 30 then
		deli(stats, 1)
	end

	for i = 1, #stats do
		avg += stats[i]
	end

	avg = avg / 30
end
 
function _draw()
	cls()

	print("cpu: " .. cpu)
	print("avg: " .. avg)
	print("noise: " .. noise)
	print("dist: " .. dist)
	print("")

	for i = 0, 3 do
		print("ch" .. i .. ": " .. stat(46 + i) .. " : " .. stat(50 + i))
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
