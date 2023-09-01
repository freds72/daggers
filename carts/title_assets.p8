pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include px9.lua

local addr=tonum(stat(6))
addr=0x1240
assert(addr,"missing target address")

-- gfx assets
-- pal({[0]=0,128,130,133,5,134,137,7,136,8,138,139,3,131,129,135},1)
local clen=px9_comp(0,0,128,64,0x8000,sget)
cstore(addr,0x8000,clen,"title.p8")

__gfx__
0000000000000000000000000000000032200000b000000000000000000000000020211111020111331110011112110000202111110201113311100111121100
0000000000000000000000000000000043500000eb00000000000000000000000133333332233332233322233333211001333333322333322333222333332110
0000000000000000000000000000000054f00000eab0000000000000000000001313322223322222222223322222321113133222233222222222233222223211
00000000000000000000000000000000f9a00000eaab000000000000000000001123222222222122222222222222232111232222222221222222222222222321
0000000000000000000000000000000078b00000eaaab00000000000000000001222222222221111122222222222222112222222222211111222222222222221
0000000000000000000000000000000052d00000eaee000000000000000000001122221222210012222222222122222111222212222100122222222221222221
0000000000000000000000000000000041e000000e00000000000000000000001122222220111121122212222222222111222222201111211222122222222221
00000000000000000000000000000000000000000000000000000000000000000122221121111112222222121022221001222211211111122222221210222210
00000000000000000000000000000000000000000000000000000000000000000112211112222121222222211102211001122111122221212222222111022110
00000000000000000000000000000000000000000000000000000000000000000122211222222211222222222112221001222112222222112222222221122210
00000000000000000000000000000000000000000000000000000000000000000022222222221221222222222222220000222222222212212222222222222200
00000000000000000000000000000000000000000000000000000000000000000122222222222222222222222222221001222222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222222221001122222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000122222222222222222222222222221001222222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222222221001122222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000012222222222222222222222222310000122222222222222222222222223100
00000000000000000000000000000000000000000000000000000000000000000012222222222222222222222222210000122222222222222222222222222100
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222201221001122222222222222222222222012210
00000000000000000000000000000000000000000000000000000000000000000122222220222222222222222221002001222222202222222222222222210020
00000000000000000000000000000000000000000000000000000000000000001112222201222222222222222222111011122222012222222222222222221110
00000000000000000000000000000000000000000000000000000000000000001122220012222222122222222222221111222200122222221222222222222211
00000000000000000000000000000000000000000000000000000000000000001222221122221222122122222222221112222211222212221221222222222211
00000000000000000000000000000000000000000000000000000000000000001122211222222222112222222112231111222112222222221122222221122311
00000000000000000000000000000000000000000000000000000000000000001112222222222122121222211112311011122222222221221212222111123110
00000000000000000000000000000000000000000000000000000000000000001222222222012122211111121122331012222222220121222111111211223310
00000000000000000000000000000000000000000000000000000000000000000122222222122222121111022222232101222222221222221211110222222321
00000000000000000000000000000000000000000000000000000000000000000122221222222222210012222122211101222212222222222100122221222111
00000000000000000000000000000000000000000000000000000000000000000122222222221222111122222222231101222222222212221111222222222311
00000000000000000000000000000000000000000000000000000000000000000122222222222122221222222222131101222222222221222212222222221311
00000000000000000000000000000000000000000000000000000000000000000112222222122222222221122223111101122222221222222222211222231111
00000000000000000000000000000000000000000000000000000000000000000011111111111111211111111111111000111111111111112111111111111110
00000000000000000000000000000000000000000000000000000000000000000000111011001111000011000001110000001110110011110000110000011100
00000000000000000000000000000000000000000000000000000000000000000020211111020111331110011112110000202111110201113311100111121100
00000000000000000000000000000000000000000000000000000000000000000133333332233332233322233333211001333333322333322333222333332110
00000000000000000000000000000000000000000000000000000000000000001313322223322222222223322222321113133222233222222222233222223211
00000000000000000000000000000000000000000000000000000000000000001123222222222122222222222222232111232222222221222222222222222321
00000000000000000000000000000000000000000000000000000000000000001222222222221111122222222222222112222222222211111222222222222221
00000000000000000000000000000000000000000000000000000000000000001122221222210012222222222122222111222212222100122222222221222221
00000000000000000000000000000000000000000000000000000000000000001122222220111121122212222222222111222222201111211222122222222221
00000000000000000000000000000000000000000000000000000000000000000122221121111112222222121022221001222211211111122222221210222210
00000000000000000000000000000000000000000000000000000000000000000112211112222121222222211102211001122111122221212222222111022110
00000000000000000000000000000000000000000000000000000000000000000122211222222211222222222112221001222112222222112222222221122210
00000000000000000000000000000000000000000000000000000000000000000022222222221221222222222222220000222222222212212222222222222200
00000000000000000000000000000000000000000000000000000000000000000122222222222222222222222222221001222222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222222221001122222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000122222222222222222222222222221001222222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222222221001122222222222222222222222222210
00000000000000000000000000000000000000000000000000000000000000000012222222222222222222222222310000122222222222222222222222223100
00000000000000000000000000000000000000000000000000000000000000000012222222222222222222222222210000122222222222222222222222222100
00000000000000000000000000000000000000000000000000000000000000000112222222222222222222222201221001122222222222222222222222012210
00000000000000000000000000000000000000000000000000000000000000000122222220222222222222222221002001222222202222222222222222210020
00000000000000000000000000000000000000000000000000000000000000001112222201222222222222222222111011122222012222222222222222221110
00000000000000000000000000000000000000000000000000000000000000001122220012222222122222222222221111222200122222221222222222222211
00000000000000000000000000000000000000000000000000000000000000001222221122221222122122222222221112222211222212221221222222222211
00000000000000000000000000000000000000000000000000000000000000001122211222222222112222222112231111222112222222221122222221122311
00000000000000000000000000000000000000000000000000000000000000001112222222222122121222211112311011122222222221221212222111123110
00000000000000000000000000000000000000000000000000000000000000001222222222012122211111121122331012222222220121222111111211223310
00000000000000000000000000000000000000000000000000000000000000000122222222122222121111022222232101222222221222221211110222222321
00000000000000000000000000000000000000000000000000000000000000000122221222222222210012222122211101222212222222222100122221222111
00000000000000000000000000000000000000000000000000000000000000000122222222221222111122222222231101222222222212221111222222222311
00000000000000000000000000000000000000000000000000000000000000000122222222222122221222222222131101222222222221222212222222221311
00000000000000000000000000000000000000000000000000000000000000000112222222122222222221122223111101122222221222222222211222231111
00000000000000000000000000000000000000000000000000000000000000000011111111111111211111111111111000111111111111112111111111111110
00000000000000000000000000000000000000000000000000000000000000000000111011001111000011000001110000001110110011110000110000011100
