pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
-- voxel editor
-- @freds72
#include debug.lua
#include ui.lua
#include maths.lua
#include poly.lua
#include voxel_editor.lua



__gfx__
01111000000100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17776100001710000017100077007700000000000000000000000000111100000000000000000000000000000000000000000000000000000000000000000000
17771000011711000100010077777700000000000000000000000000212200000000000000000000000000000000000000000000000000000000000000000000
17677100171776101700071070770700000000000000000000000000353100000000000000000000000000000000000000000000000000000000000000000000
16167710167777100100010077777700000000000000000000000000454400000000000000000000000000000000000000000000000000000000000000000000
01016100016776100017100007777000000000000000000000000000515400000000000000000000000000000000000000000000000000000000000000000000
00001000001761000001000007007000000000000000000000000000651500000000000000000000000000000000000000000000000000000000000000000000
00000000000110000000000000000000000000000000000000000000777600000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000082e200000000000000000000000000000000000000000000000000000000000000000000
77777000070000007070700000070000000700000070000007770000942400000000000000000000000000000000000000000000000000000000000000000000
70770700077000000000000000777000000070000777000000700000a94400000000000000000000000000000000000000000000000000000000000000000000
70000700077700007000700007777700077777000000000000000000b34400000000000000000000000000000000000000000000000000000000000000000000
70000700077000000000000070777000707770000000000000000000ccc400000000000000000000000000000000000000000000000000000000000000000000
70770700070000007070700070070000700700000000000000000000d51400000000000000000000000000000000000000000000000000000000000000000000
77777700000000000000000077700000000000000000000000000000e2d400000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000f45400000000000000000000000000000000000000000000000000000000000000000000
00777700000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07aaaa7000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a9009a706b36b700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a0000a9003b1300001e780000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a0000a900363b00012ee78000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a7007a90494994000122e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09a77a90005555000002200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900002442000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
