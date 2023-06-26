pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

#include debug.lua
#include main_maths.lua
#include plain.lua
#include common.lua
#include assets.lua
#include audio.lua
#include main.lua

__gfx__
00000000000000000000000000000000444700007f5982ee00000000008000001131355555534555555555555555553202111111111110000100000000000110
00000000000000000000000000000000555600000000000000000000080800001254555555545554545444444445455321100000000000000000000000000001
00000000000000000000000000000000666500000000000000000000800080002454544444545444444444444444433511110000000000000000000000000001
000000000000000000000000000000007b9800000000000000000000080800002544444444444334444444444444443511100000000000000000000000000001
000000000000000000000000000000006c8200000000000000000000008000002344444444443334444444444444444510100000000000000000000000000000
000000000000000000000000000000005d2300000000000000000000000000002344444444241122244444343444445510000000000000000000000000000001
000000000000000000000000000000004e1400000000000000000000000000002344444443122222234443434444445510000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001234344431222323233222344444445510000000000000000000000000000000
00000000000000000000000000000000700000001111111100000000000000001224222222222232333334444444445510000000000000000000000000000000
00000000000000000000000000000000d70000001111111100000000000000001244222224432223333344444444433510000000000000000000000000000000
00000000000000000000000000000000da7000001111111100000000000000001144223444442333333344444444435500000000000000000000000000000000
00000000000000000000000000000000daa700001111111100000000000000001244333444443333333444444443434510000000000000000000000000000000
00000000000000000000000000000000daaa70001111111100000000000000001234333444444333334443343434445410000000000000000000000000000000
00000000000000000000000000000000dadd00001111111100000000000000001244344334344443334444444434445300000000000000000000000000000000
000000000000000000000000000000000d0000001111111100000000000000001144344443434444444444443333333300000000000000000000000000000000
00000000000000000000000000000000000000001111111100000000000000001144444444444444444444444444444110000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000001144544444444444444444444441444500000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000001244444444444444444444444444444500000000000000000000000000000021
00000000000000000000000000000000000000000000000000000000000000002444444444444444444343444444453500000000000000000000000000000021
00000000000000000000000000000000000000000000000000000000000000002344334444444444444444443342443300000000000000000000000000000011
00000000000000000000000000000000000000000000000000000000000000002344454444444444444444443342443500000000000000000000000000000001
00000000000000000000000000000000000000000000000000000000000000002344444444444444444433232342445500000000000000000000000000000001
00000000000000000000000000000000000000001111111100000000000000002344444444444444444444433342445500000000000000000000000000000001
00000000000000000000000000000000000000001111111100000000000000001234444444444444444444433332442500000000000000000000000000000001
00000000000000000000000000000000000000001111111100000000000000001244444444444444444444433332432500000000000000000000000000000001
00000000000000000000000000000000000000002222222200000000000000001244444444444444444444444432425500000000000000000000000000000001
00000000000000000000000000000000000000002222222200000000000000001143444344443344444444444431433500000000000000000000000000000001
00000000000000000000000000000000000000002222222200000000000000001244434433344433444434444431233500000000000000000000000000000000
00000000000000000000000000000000000000003333333300000000000000001234443333344443444344444344245300000000000000000000000000000001
00000000000000000000000000000000000000003333333300000000000000001234442222222333333344443431435510000000000000000000000000000000
00000000000000000000000000000000000000003333333300000000000000001134443222333332223344434344433510000000000000000000000000000000
00000000000000000000000000000000000000004444444400000000000000001111112222222221122222221111113200100000000000000001122110000000
__label__
88888888888888888222222288888888888888888888888888888888888888888888888899999999aaaaaaaa77777777ccccccccddddddddeeeeeeeeffffffff
88882888882222288200222288288888888888f88882828288888828888882888888888899999999aaaaaaaa70000007ccccccccddddddddeeeeeeeeffffffff
8882228888822288822022228222888888888fff8888888888888882888822288888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
882222288888288882202222888888888888fffff882888288882222288888888888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88888888888888888220222288888888888f8fff8888888888828222888888888888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88288828882888288200022282228888888f88f88882828288828828888822288888888899999999aaaaaaaa70bbbb07ccccccccddddddddeeeeeeeeffffffff
88222228882222288222222288288888888fff888888888888888888888882888888888899999999aaaaaaaa70000007ccccccccddddddddeeeeeeeeffffffff
88888888888888888222222288888888888888888888888888888888888888888888888899999999aaaaaaaa77777777ccccccccddddddddeeeeeeeeffffffff
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000333333400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000666666666666666666666666666666666666666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000603333333400000000000000000000000000000060000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000600555555540000000000000004bbbbbbb000000060000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000600555555540000000000000004bbbbbbb000000006000000000000000000000000000000000000000000
0000000000000000000000000000000000000000006000555555540000000000000004bbbbbbb000000006000000000000000000000000000000000000000000
00000000000000000000000000000000000000000060000555555400033333333bbbbbb55555bbbbbbbb00600000000000000000000000000000000000000000
00000000000000000000000000000000000000000600000555555400033333333bbbbbb555554bbbbbbb00600000000000000000000000000000000000000000
00000000000000000000000000000000000000000600000000000000033333333bbbbbb555554bbbbbbbb0060000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000000000000033333333bbbbbb555554bbbbbbbb0060000000000000000000000000000000000000000
00000000000000000000000000000000000000006000000003333333355555555555555555554455555555006000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000003333333345555555555555000044555555550006000000000000000000000000000000000000000
00000000000000000000000000000000000000060000000003333333345555555555555000004555555550000600000000000000000000000000000000000000
00000000000000000000000000000000000000600000000033333333345555555555555000004555555550000600000000000000000000000000000000000000
00000000000000000000000000000000000000600000000033333333345555555555555000004555555500000060000000000000000000000000000000000000
000000000000000000000000000000000000060033333333bbbbbbbb333333333bbbbbbb33333333000000033363333300000000000000000000000000000000
00000000000000000000000000000000000006033333333bbbbbbbb3333333333bbbbbbbb3333333300000043336333330000000000000000000000000000000
00000000000000000000000000000000000060033333333bbbbbbbb3333333333bbbbbbbb3333333300000443336333330000000000000000000000000000000
00000000000000000000000000000000000060033333333bbbbbbbb3333333333bbbbbbbb3333333300000443333633333000000000000000000000000000000
00000000000000000000000000000000000600333333333bbbbbbbb3333333333bbbbbbbb3333333300004444333633333000000000000000000000000000000
0000000000000000000000000000000000060033333333bbbbbbbbb3333333333bbbbbbbb3333333330004444333363333300000000000000000000000000000
0000000000000000000000000000000000600333333333bbbbbbbbb3333333333bbbbbbbb3333333330004444433363333330000000000000000000000000000
000000000000000000000000000033333363334555555533333333335555555555555555bbbbbbbbbb0000444555556555500000000000000000000000000000
0000000000000000000000000003333336333445555553333333333455555555555555554bbbbbbbbbb000444555556555000000000000000000000000000000
0000000000000000000000000003333336333444555553333333333455555555555555554bbbbbbbbbb000445555555655000000000000000000000000000000
0000000000000000000000000033333363334444555553333333333455555555555555554bbbbbbbbbb000045555555150000000000000000000000000000000
0000000000000000000000000333333363334444455533333333333445555555555555544bbbbbbbbbbb00077777771710000000000000000000000000000000
0000000000000000000000000333333633344444400033333333333440000000000000044bbbbbbbbbbb00070000010071000000000000000000000000000000
0000000000000000000000003333333633344444000033333333333400000000000000004bbbbbbbbbbb00007000170077100000000000000000000000000000
0000000000000000000000003333336333344444000033333333333400000000000000004bbbbbbbbbbb00007000010001000000000000000000000000000000
0000000000000000000000005555556555544440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000700001717600000000000000000000000000000
0000000000000000000000000555565555554440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000700000100700000000000000000000000000000
0000000000000000000000000055565555555440000bbbbbbbbbb333333333333bbbbbbbbbb33333333330000070000000760000000000000000000000000000
000000000000000000000000000065555555550000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000077777777770000000000000000000000000000
000000000000000000000000000060000000000000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000000000000006000000000000000000000000000
000000000000000000000000000600000000000000bbbbbbbbbbb333333333333bbbbbbbbbb33333333333000000000000006000000000000000000000000000
00000000000000000000000000060000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000600000000000000000000000000
00000000000000000000000000600000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000600000000000000000000000000
00000000000000000000000000600000000000000bbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333300000000000000060000000000000000000000000
0000000000000000000000000600000000000000bbbbbbbbbbbb3333333333333bbbbbbbbbbb3333333333330000000000000060000000000000000000000000
00000000000000000000000006000000000000000555555555555555555555555555555555555555555555500000000000000006000000000000000000000000
00000000000000000000000060000000000000000555555555555555555555555555555555555555555555500000000000000006007770000000000000000000
00000000000000000000000060000000000000000055555555555555555555555555555555555555555555000000000000000000607070000000000000000000
00000000000000000000000666666666666666666666666666666666666666666666666666666666666666666666666666666666607070000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007070000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
08090a0b161616160c0d0e0f0707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18191a1b151515151c1d1e1f0707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
28292a2b151515152c2d2e2f0707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
38393a3b353535353c3d3e3f0707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000292929292900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0901000f0025000170002500017000250001700025000170002500017000250001700025000170002500010000200002000020000200002000020000200002000020000200002000020000200002000020000200
450211200047000470004400044000400004000046000460004520045200462004620040000400003720047200400004000037000470004700040000372004720040000400003700047000470004000037200472
090115203e0323d0313c0313d0413b0413e0413d0313c0313c0213b0213b0113c0113b0113b0113c0113b0113b0123b0123c0113b0123c0113c7123c7123c7103c7123c7123c7103c7123c7103c7103c7123c712
450204081844018440184101841018440184401842018420184401844018410184101844018440184101841018400184001835018450184501840018352184521840018400183501845018450184001835218452
c10100011871100700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
45020005000720c3300c3620037224322186000c6000c60024000184000c0000c00018400186000c3000c10018400184001840018400184001840018400184001840018400184001840018400184001840018400
4301000d2464225032246412465124611230322464224631250212464218652246422302100600006000060000600006000060000600006000060000600006000060000600006000060000600000000000000000
310100001be1527e0527e1527e0527f0527f151bf1533f051bf1533f0027f1533f0533f051bf1533f001bf151bf1533f0027f0527f1533f0027f051bf1527f051bf151bf0527f1527f051bf051bf051bf1500005
330800002f924336412f934336512f934336412f924276412f8340c8400d8410e8410e8410f8410f84110841118411184112841128421284212842128421284212842128421284212842128420c8410c8210c811
7b1000001c8111c8211c8311c8311c8411c8411c8411c8411c8511c8511c8511c8511c8411c8411c8411c8311c8311c8311c8211c8211c8211c8311c8311c8411c8411c8411c8511c8411c8311c8211c8111c811
3f04000012622080622073514055216251906524625177711c8211b8211c8211b8211c8311b8311c8311b8311c8311b8311c8311b8311c8311b8311c8311b8311c8311b8311c8311b8211c8211b8211c8111b811
470f00001a81027635266351b811266351a8112563519811246351c81120635198211f622198111c821198211a821188311983118831198311883119831188311983118831198311882119821188211981118811
3305000033013336511b645246610061104611076110b6112f0132f671176450c611106111361115611176111a6111c611146712c0132c6711464524611286112b6112e0132e671166451c611106110c61100611
2d0b000012a3412a3411a3411a3410a3410a340fa340fa340ea340ea340da340da340ca340ca340ca340ba240ba240ba1403a0403a0401a0401a0401a0400a040000400004000040000400004000040000400004
43080000179643b6112061108945169643a6111f61107945169643a6111f6110794515964396111e6110694514954386111d6110593514954386111d6110593514944386111d6110591513934376111c61104915
4310000025e4123e4110e4025e4123e4110e4023e4123e4112e4024e4123e4125e4125e4133e1222e4122e4124e4125e310fe3025e3123e3112e3025e2127e211fe2025e2127e211ae2023e1126e1127e1119e11
0104000024f5532f5525f6531f7424f5500f0024f7430f5500f0025f7000f0000f0032f5525f6519f740cf5500f0030f5418f750df7424f5500f0024f7430f7524f7418f7000f0000f0000f0024f7430f0019f75
010900001af7525f6519f7424f5524f7424f7519f7526f7519f5525f7524f5525f7424f5524f7418f7518f7526f7525f6519f7424f5524f7424f7519f7018f5518f7424f7525f7026f6525f7424f5519f7424f55
0109000024f5532f5525f6531f7424f5500f0024f7430f5519f5525f7524f5525f7424f5524f7418f7518f7500f0030f5418f750df7424f5500f0024f7430f7518f7424f7525f7026f6525f7424f5519f7424f55
0006000021f5528f6523f742ef7524f7424f6529f7526f7519f5525f752df6520f741ef552af7418f7518f7526f751ef651df7424f5519f742bf7519f7018f5523f7424f7529f501bf6525f741ef5523f3424f15
3310000010e2132e3132e4132e4131e4131e4130e4130e4130e412fe412fe412ee412fe4130e412fe4130e412fe4130e412fe4130e412fe4130e412fe4130e3131e3130e3131e2132e2131e2132e1131e1132e11
311000002fe302fe412ce4123e422fe412fe452fe412fe452fe402fe412ce4123e422fe412fe452fe412fe452fe402fe412ce4123e422fe312fe352fe312fe352fe302fe312ce3123e322ee212ee252de212de15
331000002ee302ce412ce412ce422be412be452ae412ae452ae4129e4129e4129e4229e4129e4529e4129e4529e4129e4129e4129e4229e412ae352ae312ae352ae312ae312be312be222be212be252ce112ce15
330e00001fe1020e3122e4111e411fe4121e4220e4118e4220e411ee411de411be4210e4119e4210e4119e420de4019e4119e410ce4119e4111e4119e3113e311ce3113e311ee3115e211ee211de211ce211be11
a32000000f81212821128211282212831128321283212832128321283212832128321283212832128321283211831108310f8310f8320f8320f8320f8320f8320f8320f8320f8320f8320f8320f8320f8210f811
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
390900001862204631076210c631106411365118661186000c000000000000007600136441365413664136740b07100612076410e63110631186311001010010100101001010021100311004110010100100e011
350900000c073170221702117025170141702417034171541d0241e0141f0141d01417354173540b3640b36400072132001320013200132001320007252132520725213042137411271113711137110000000000
350900002370023700237112372123031230422304223042233152331223035237352272123711237112371118640186200000013100131331701017110170101611117121170321703217741177111771117711
2d0900000000000000000001f7001f7101d7311f7311f711137312311217110000000000017123171331714317153000000b20017271172552371223711237112372122721237312274123721217110000000000
3b0a0000336713364124641246412f6312e6312d6312c6002b6712a6002967128600266612460023600216411f6511d6001c6001a600186411760015600136410c6410b621096210762105621046210262100611
010a00001686017860188601a8601a8601a8601986019860198601a86018860198601886016860178601586015860148601286012860108600d8600b860088600686002860008700180000870000000086000000
3d0a000004a5206a7108a710ba710da710da720da720da720da620da620da520da520da420da420da320da220da1201a110000100001000010000100001000010000100001000010000100001000010000100001
3e04000023670326502ee502ee402ee502ee402ee302e6512d6412a6412464129651226412465121651176411d64118641196410f641136410f641096410b64103631146311f6311b6211f621246212061100000
3b040000186420e032267151a025246351a035246251a7212462215e1215e1515e1515e1015e2515e3516e3516e1617e3618e2617e1616e3615e1615e3614e1615e3613e1612e360fe160ce3609e1606e3604e16
010a000024f6532f6525f7531f7424f6500f0024f7430f6500f0025f700d9100f9111191115911189111ca211ca311ca311ca211ca111ca111ca111ca211ca311ca311ca311ca211ca111ca111ca111ca211ca11
6310000023e4124e5125e5128e5128e512ae512ce512fe4133e211fe511ee411fe411ee411fe411ee411de411ee411ce411de411ce411be411be411ae3119e3116e3113e3110e210ce2108e1103e110000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
39070000100500da600da510da510da510da510da510da410da410da410da310da310da210da1121911239211893123941239322493223932249322193221932219311e9321e9311e9311c9311c9321b92518911
c10700001ba721ba7119a6119a6119a6119a6219a5219a5219a5219a4219a3219a2224b1426b2524b212bb212bb212fb2104b212fb252fb252fb252fb2525b2125b2127b1527b1527b1526b1526b151b9001a900
810700001da00117001ca621ea511ea411ea411ea311ea321ea221ea221ea121ea1230b1432b1134b2135b2137b2137b1135b1235b1535b1535b1530b112db1129b112bb151eb151eb151eb151eb111eb111eb11
31070000000000000000000000001dc111dc111dc211dc211dc311dc311dc312fb142fb122fb121dc621dc711dc111dc111dc211dc211dc311dc311dc411dc411dc511dc511dc611dc711dc511dc611dc511dc11
330110000c32019c111ac3219c303b6201901018c2115c111cc211171119c30117111cc111171119c301171100000000000000000000000000000000000000000000000000000000000000000000000000000000
41010000256720a0720a6221c672090703a620386200907034621050710407104071020710a6710a6710a67125211220311e6511d2411b64118241160311425111251102410f0610f2610d0510d0410b04107031
070e01003267500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30030000020500c655020302c61500030206103e615216203e615216203b6152162038615366153361532615306102d61029610226101c610186101461014610176101b6100e610216003d600166001a6001b600
310100000f630266300f610236200f0100f6300f63017011176300f01121610216100f0100f0102261016010160111f011167111e610157102061113711226101171024610107101f6100d710200012300124001
01030000246421a042327152603530635260453062532731306120e4251c2250e42530620107550e435306351861224621306213c6153c6150000000000000003c6102461118611006110000000000000003c000
010a00002681124821268212481126821248212681124821268212481126811248212682124811268212482126811248212681124821268212481126821248212682124821268212482126821248112681124811
030a0000186430cd6327d2132d2133d2132d2132d2133d2132d2133d2132d2133d2132d2131d2130d212ed212fd212ed212dd212ed212dd21246212662128621296212b6212d6212f61130611326113461135611
2f041800318332583330833248333b8321883101a310ea310fa3110a310fa3110a310fa3110a310fa3110a210fa2110a210fa2110a110fa1110a110fa1110a110000000000000000000000000000000000000000
3303000011e401de511d6701d6711de7011e70110501d0501d0501173018620117301d620117302362011730286201173028620296152d6153061534615000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410a00001865023631216311f6311d6311c6311a6311863117621156211362111621106210e6210c611176110c6111a6111c6111d6111f6112161123611246112661128611296113f6113e6003c6000000000000
470a00000d6700d670010610106101051010510104101041010310103101031010210102101021010110101100000000000000000000000000000000000000000000000000000000000000000000000000000000
250a000019a3025a3219a320db6225b6125b6225b6225b6225b6225b6225b6225b6221b5021b6121b6021b6020b6020b7120b6020b7020b4020b5020b4020b5020b3020b4020b3020b4020b2020b3020b2020b10
010a0000259402594025940259402594025940259402594025930269302793028920299202a920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 20212223
00 41424344
00 41424344
00 41424344
00 24252627
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 2c2d2e2f
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 36373344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 3c3d3e3f

