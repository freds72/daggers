pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--devil daggers sfx
--by ridgek

--sfx
--08: chattersquid
--09: chattersquid2
--10: chattersquid3
--11: chattersquid4
--12: chatterskull
--13: chatterskull2
--14: chatterskull3
--15: chatterskull4
--16: chatterspiderling
--17: chatterspiderling2
--18: chatterspiderling3
--19: chatterspiderling4
--20: chattercentipede
--21: chattercentipede2
--22: chattercentipede3
--23: chattercentipede4
--24: chatterspider
--25: chatterspider2
--26: chatterspider3
--27: chatterspider4
--28: death, killsquid
--29: spawnskulls
--30: spawnspider
--31: spawncentipede
--32: spawnmine
--33: eggbounce (unused? previously 50)
--34: eggburst, killcentipede
--35: killskull1, killspider
--36: killspiderling
--37: killcentipede
--38: killcentipede
--39: burrowcentipede
--40: unburrowcentipede
--41: highscore1
--42: highscore1
--43: highscore1
--44: spawnplayer
--45: spawnplayer
--46: spawnplayer
--47: spawnplayer
--48: death
--49: death
--50: death
--51: ambient
--52: levelup
--53: levelup
--54: levelup
--55: levelup
--56: leveldown
--57: collectgibbase1
--58: jump
--59: damagejewel
--60: rapid1
--61: shot1
--62: shot2
--63: shot3

--music
--28: killsquid
--37: killcentipede
--41: highscore1
--44: spawnplayer
--48: death
--52: levelup

--prevent run if loaded from packer.p8
if stat(6) == "stop" then
	stop()
end

--copy all sfx/music to daggers.p8
cstore(0x3100,0x3100,0x1200,"../carts/freds72_daggers.p8")

--copy chatter 8-18 backup for victory music to chatter.p8
cstore(0, 0x3420, 0x2ec, "./chatter.p8")

---prepare noise engine data
--0x0000-0x23: sfx effect bytes (title.lua)
--0x0024-0x04a3: note high bytes (title.lua)
--0x04a4-0x05a3: sfx effect bytes damp 0 (title.lua)
--0x05a4-0x0603: sfx effect bytes damp 1 (title.lua)
--0x06a4-0x07a3: sfx effect bytes damp 2 (title.lua)
--0x07a4-0x08a3: note high bytes attn 0 (title.lua)
--0x08a4-0x09a3: note high bytes attn 1 (title.lua)
--0x09a4-0x0aa3: note high bytes attn 2 (title.lua)
for sfx_idx = 8, 43 do
		local offset = sfx_idx * 68

		--write effect byte
		local effect_byte = @(0x3200 + offset + 64)

		poke(0x0000 + (sfx_idx - 8), effect_byte)

		--write note high bytes
		for note_idx = 0, 31 do
			local hi_byte = @(0x3200 + offset + (note_idx * 2) + 1)

			poke(0x0024 + ((sfx_idx - 8) * 32) + note_idx, hi_byte)
		end
end

--loop attenuation levels
for attn = 0, 2 do
		--loop all possible bytes
		for i = 0, 255 do
				local byte = i

				--set editormode + noiz + buzz
				byte = i & 0b111
				--set detune
				byte += (i \ 8 % 3) * 8
				--set reverb
				--@todo test this
				--byte += max(byte \ 24 % 3, attn) * 24
				byte += (i \ 24 % 3) * 24
				--set dampen
				byte += attn * 72

				poke(0x04a4 + (attn * 256) + i, byte)
		end
end

--loop attenuation levels
for attn = 0, 2 do
		--loop all possible bytes
		for i = 0, 255 do
				local byte = i
				--decoded volume bits of byte
				local vol = (i & 0b00001110) >>> 1
				local new_vol = max(1, vol - attn)

				byte = (i & 0b11110001) | (new_vol << 1)

				poke(0x07a4 + (256 * attn) + i, byte)
		end
end

--copy noise engine data to noise.p8
cstore(0, 0, 36 + (32 * 36) + 0x0300 + 0x0300, "./noisedata.p8")

--run packer.p8
load("./audio/packer.p8", nil, "./audio/sfx.p8")

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0901000f0025000170002500017000250001700025000170002500017000250001700025000170002500010000200002000020000200002000020000200002000020000200002000020000200002000020000200
450211200047000470004400044000400004000046000460004520045200462004620040000400003720047200400004000037000470004700040000372004720040000400003700047000470004000037200472
090115203e0323d0313c0313d0413b0413e0413d0313c0313c0213b0213b0113c0113b0113b0113c0113b0113b0123b0123c0113b0123c0113c7123c7123c7103c7123c7123c7103c7123c7103c7103c7123c712
450204081844018440184101841018440184401842018420184401844018410184101844018440184101841018400184001835018450184501840018352184521840018400183501845018450184001835218452
c10100011871100700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
45020005000720c3300c3620037224322186000c6000c60024000184000c0000c00018400186000c3000c10018400184001840018400184001840018400184001840018400184001840018400184001840018400
4301000d2464225032246412465124611230322464224631250212464218652246422302100600006000060000600006000060000600006000060000600006000060000600006000060000600000000000000000
310100001be1527e0527e1527e0527f0527f151bf1533f051bf1533f0027f1533f0533f051bf1533f001bf151bf1533f0027f0527f1533f0027f051bf1527f051bf151bf0527f1527f051bf051bf051bf1500005
330800002f934336512f944336612f944336612f934276512f8440c8500d8510e8510e8410f8410f84110851118511185112861128621285212852128421284212842128421284212842128420c8410c8210c811
331000001c8111c8211c8311c8311c8411c8411c8411c8411c8511c8511c8511c8511c8411c8411c8411c8311c8311c8311c8211c8211c8211c8311c8311c8411c8411c8411c8511c8411c8311c8211c8111c811
3f04000012622080622073514055216251906524625177711c8211b8211c8211b8311c8311b8311c8411b8411c8411b8511c8511b8411c8411b8411c8411b8311c8311b8311c8311b8311c8211b8211c8211b811
470f00001a82027635266351b821266351a8212563519821246351c82120635198211f622198211c821198211a831188311983118831198411884119851188411984118831198311882119821188211981118811
3b05000033023336611b635246610063104621076210b6112f0232f661176550c621106211362115611176111a6111c611146712c0332c6611464524631286212b6112e0232e621166451c621106210c61100611
2d0b140012a3412a3411a3411a3410a3410a340fa340fa340ea340ea340da340da340ca340ca340ca340ba340ba340ba2403a1403a0401a0401a0401a0400a040000400004000040000400004000040000400004
43080000179743b6312062108945169743a6211f63107945169743a6111f6310794515964396111e6310694514954386111d6210593514954386111d6210593514944386111d6210591513934376111c62104915
4310000025e4123e7110e5125e4123e6110e6023e6123e7112e5024e4123e5125e7125e512fe1222e4122e6124e6125e310fe3025e3123e5112e4025e4127e211fe3025e4127e211ae3023e4126e2127e2119e11
010400000cf5532f5525f6531f7424f5500f0024f7430f5500f0025f7000f0000f0032f5525f6519f740cf5500f0030f5418f750df7424f5500f0024f7430f7524f7418f7000f0000f0000f0024f7430f0019f75
010900001af7525f6519f7424f5524f7424f7519f7526f7519f5525f7524f5525f7424f5524f7418f7518f7526f7525f6519f7424f5524f7424f7519f7018f5518f7424f7525f7026f6525f7424f5519f7424f55
0109000024f5532f5525f6531f7424f5500f0024f7430f5519f5525f7524f5525f7424f5524f7418f7518f7500f0030f5418f750df7424f5500f0024f7430f7518f7424f7525f7026f6525f7424f5519f7424f55
0106000021f5528f6523f742ef7524f7424f6529f7526f7519f5525f752df6520f741ef552af7418f7518f7526f751ef651df7424f5519f742bf7519f7018f5523f7424f7529f501bf6525f741ef5523f3424f15
3310000010e3132e4132e5132e5131e5131e5130e5130e6130e612fe612fe512ee512fe5130e512fe5130e512fe4130e412fe4130e412fe4130e412fe3130e3131e3130e3131e3132e2131e2132e2131e2132e11
311000002fe402fe512ce5123e622fe612fe652fe512fe552fe502fe512ce5123e522fe512fe552fe512fe552fe402fe412ce4123e422fe412fe352fe312fe352fe302fe312ce3123e222ee212ee252de212de15
331000002ee402ce512ce512ce622be612be652ae612ae652ae6129e5129e5129e5229e5129e5529e4129e4529e4129e4129e4129e4229e312ae352ae312ae352ae312ae212be212be222be212be252ce212ce15
330e00001fe4020e6122e7111e711fe7121e7220e7118e7220e611ee611de611be6210e6119e5210e5119e520de5019e5119e510ce4119e4111e4119e4113e411ce4113e311ee3115e311ee311de211ce211be11
390a130014f651ff6514f650ff650ff5016f5114f651ff6514f651ff6514f650ff650ff5015f6515f5017f6514f651ff6514f6500000000000000000000000000000000000000000000000000000000000000000
390a130014f651ff6520f6514f6514f651ff6520f6514f6520f651ff6520f651ff6514f651ff6520f6513f6514f651ff6514f6500000000000000000000000000000000000000000000000000000000000000000
390a130020f651ff6520f651ff6514f6520f6515f652bc1114f3514e2522e1127f4527f2519f6120f651ff6520f651ff650000000000000000000000000000000000000000000000000000000000000000000000
390a13000ff4015f6515f4017f6514f651ff6514f651ff650ff4015f6515f4017f6514f651ff6514f6517f650ff4015f6515f4000000000000000000000000000000000000000000000000000000000000000000
3f040000326711a671026712ee402ee502ee4022670226702d6712a6712467129671226712466121661176611d66118661196510f651136510f651096410b64103631146311f6311b6211f621246212061100000
3b040000186620e052267351a045246551a055246451a7412464215e3215e3515e3515e3015e4515e5516e5516e3617e5618e4617e3616e5615e3615e5614e3615e5613e3612e560fe360ce4609e2606e3604e16
010a000010f6532f6525f7531f7424f6500f0024f7430f6500f0025f700d9100f9111191115911189111ca211ca311ca311ca211ca111ca111ca111ca211ca311ca311ca311ca211ca111ca111ca111ca211ca11
1b10000023e510de6125e6128e6128e612ae712ce712fe7133e211fe511ee711fe711ee711fe611ee611de611ee511ce511de511ce411be411be411ae3119e3116e3113e3110e210ce2108e1103e1100e1100e01
330300000d6711f6401f6312063121631236412565127641306413b63133621184320c341187510c7610074100742007420074200742007420073200732007320073200732007220072200722007220071200701
070e01003267500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30030000020500c655020302c61500030206103e615216203e615216203b6152162038615366153361532615306102d61029610226101c610186101461014610176101b6100e610216003d600166001a6001b600
310100000f640266400f620236300f0500f6400f64017051176400f05121620216100f0400f0312262016030160111f011167111e610157102061113711226101171024610107101f6100d710200012300124001
31030000246321a032327152602530625260353061532721306120e4151c2150e41530610107450e42530625186122461124611306153061500000000000000030610186110c611006110000000000000003c000
010a00002681124821268212481126821248212681124821268212481126811248212682124811268212482126811248212681124821268212481126821248212682124821268212482126821248112681124811
030a0000186430cd6327d2132d2133d2132d2132d2133d2132d2133d2132d2133d2132d2131d2130d212ed212fd212ed212dd212ed212dd21246212662128621296212b6212d6212f61130611326113461135611
330c00003d6403d6643167438640386542c6742c674316402e6542c6642a674276742567422674206740987008871078710687105871048710387102871018700087100861008510084100831008210082100810
1b0b00000084000840008500485004860058700787016670186702767034670356703366135661346613565134651356513465135641346413564134641356313463135631346313562134621356213461135611
410a00001865023631216311f6311d6311c6311a6311863117621156211362111621106210e6210c611176110c6111a6111c6111d6111f6112161123611246112661128611296113f6113e6003c6000000000000
250a000019a3025a3219a320db6225b6125b6225b6225b6225b6225b6225b6225b6221b5021b6121b6021b6020b6020b7120b6020b7020b4020b5020b4020b5020b3020b4020b3020b4020b2020b3020b2020b10
010a00000d6700d67001061010610105101051010410104101031269242793128921299212a921000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
390900001862204631076210c631106411365118661186000c000000000000007600136441365413664136740b07100612076410e63110631186311001010010100101001010021100311004110010100100e011
350900000c073170221702117025170141702417034171541d0241e0141f0141d01417354173540b3640b36400072132001320013200132001320007252132520725213042137411271113711137110000000000
350900002370023700237112372123031230422304223042233152331223035237352272123711237112371118640186200000013100131331701017110170101611117121170321703217741177111771117711
2d0900000000000000000001f7001f7101d7311f7311f711137312311217110000000000017123171331714317153000000b20017271172552371223711237112372122721237312274123721217110000000000
3b0a0000336713364124641246412f6312e6312d6312c6002b6712a6002967128600266612460023600216411f6511d6001c6001a600186411760015600136410c6410b621096210762105621046210262100611
010a00001686017860188601a8601a8601a8601986019860198601a86018860198601886016860178601586015860148601286012860108600d8600b860088600686002860008700180000870000000086000000
3d0a000004a5206a7108a710ba710da710da720da720da720da620da620da520da520da420da420da320da220da1201a110000100001000010000100001000010000100001000010000100001000010000100001
a32000000f81212821128211282212831128321283212832128321283212832128321283212832128321283211831108310f8310f8320f8320f8320f8320f8320f8320f8320f8320f8320f8320f8320f8210f811
430a0000336613f661336402e64127641226411b641166410f6410a64103641006410063100631006310062100621006210061100611346243262434624326243462432624346243262434624326243462433614
3d0a000000000140001601117011190111b0111d0111e0112001122011230112501127011290112a0112c0112e0112f0113101133011340113501136011370110c0000c0000c0000c00000000000000000000000
3d0a000010e0014e000f6700f670030610306117611166111ce611ae611ce611ae611ce611ae611ce611ae611ce611ae611ce611ce611ae611ce611ae511ce511be421be321be221be121be1200e000000000000
3d0a000000b000fb002263021621206221f6211e6111d6121bb311db311eb3120b3122b3124b3125b3127b3129b312ab312cb312eb312fb2130b2131b1132b110cb000cb000cb000cb000cb000cb000cb0000000
030e00001f8741f8741e8511d8511c8711b8511a851198711886117851168611584114851138311285111821108410f8210e8010d8000c8000b8000a800098000880007800000000000000000000000000000000
3303000011e401de511d6701d6711de7011e70110501d0501d0501173018620117301d620117302362011730286201173028620296152d6153061534615000000000000000000000000000000000000000000000
1906090003610276311b640166210f6310a6111891418914189140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2f041800318332583330833248333b8321883101a310ea310fa3110a310fa3110a310fa3110a310fa3110a210fa2110a210fa2110a110fa1110a110fa1110a110000000000000000000000000000000000000000
3301000b1032019c211ac3219c303b6121932018c2115c211cc211123119c301cc001170019c00117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
410100000d6620a0520a61210652090503a6102c6100905034611050510405104051020510a6510a6510a65125211220311e6511d2411b64118241160311425111251102410f0610f2610d0510d0410b04107031
41021d000d662226311662110651099503a6102c610099503461104051020510a6510a65118951159411494112941119310f9310e9310d9410d9410d9410e9410f93111921139211391113901139000000000000
410300000d6722264100070116620504011650114121594027e121294127e120994027e120994027e120993027e120993026e120992026e100991025e101ce121ce121ce1113e1113e1113e1113e110de1111e01
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 08090a44
00 0b0c0d0e
00 0f101112
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
00 1c424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 25262244
00 41424344
00 41424344
00 41424344
00 292a2b7f
00 41424344
00 41424344
00 2c2d2e2f
00 41424344
00 41424344
00 41424344
00 3031321c
00 41424344
00 41424344
00 41424344
00 34353637

