import os
import subprocess
from subprocess import Popen, PIPE
import re
import tempfile
import random
import math
import socket
import shutil
from tqdm import tqdm

def call(args):
    proc = Popen(args, stdout=PIPE, stderr=PIPE)
    out, err = proc.communicate()
    exitcode = proc.returncode
    #
    return exitcode, out, err

# pack helpers
def tohex(val, nbits):
    return (hex((int(round(val,0)) + (1<<nbits)) % (1<<nbits))[2:]).zfill(nbits>>2)

# variable length packing (1 or 2 bytes)
def pack_variant(x):
    x=int(x)
    if x>0x7fff:
      raise Exception('Unable to convert: {} into a 1 or 2 bytes'.format(x))
    # 2 bytes
    if x>127:
        h = "{:04x}".format(x + 0x8000)
        if len(h)!=4:
            raise Exception('Unable to convert: {} into a word: {}'.format(x,h))
        return h
    # 1 byte
    h = "{:02x}".format(x)
    if len(h)!=2:
        raise Exception('Unable to convert: {} into a byte: {}'.format(x,h))
    return h

# single byte (unsigned short)
def pack_byte(x):
    h = tohex(x,8)
    if len(h)!=2:
        raise Exception('Unable to convert: {} into a byte: {}'.format(x,h))
    return h
    
# short must be between -32000/32000
def pack_int(x):
    h = tohex(x,16)
    if len(h)!=4:
        raise Exception('Unable to convert: {} into a word: {}'.format(x,h))
    return h

def pack_int32(x):
    h = tohex(x,32)
    if len(h)!=8:
        raise Exception('Unable to convert: {} into a dword: {}'.format(x,h))
    return h

# 16:16 fixed point value
def pack_fixed(x):
    h = tohex(int(x*(1<<16)),32)
    if len(h)!=8:
        raise Exception('Unable to convert: {} into a dword: {}'.format(x,h))
    return h

# short must be between -127/127
def pack_short(x):
    h = "{:02x}".format(int(round(x+128,0)))
    if len(h)!=2:
        raise Exception('Unable to convert: {} into a byte: {}'.format(x,h))
    return h

# float must be between -4/+3.968 resolution: 0.03125
def pack_float(x):
    h = "{:02x}".format(int(round(32*x+128,0)))
    if len(h)!=2:
        raise Exception('Unable to convert: {} into a byte: {}'.format(x,h))
    return h
# double must be between -128/+127 resolution: 0.0078
def pack_double(x):
    h = "{}".format(tohex(128*x+16384,16))
    if len(h)!=4:
        raise Exception('Unable to convert: {} into a word: {}'.format(x,h))
    return h

def pack_vec3(v, scale=None):
  scale = scale or 1
  return pack_fixed(v.x * scale) + pack_fixed(v.y * scale) + pack_fixed(v.z * scale)

# convert a byte array to a pico8 safe char set
def bytes_to_base255(bs):    
    # safe pico chars
    chars = ["\\0","¹","²","³","⁴","⁵","⁶","⁷","⁸","	","\\n","ᵇ","ᶜ","\\r","ᵉ","ᶠ","▮","■","□","⁙","⁘","‖","◀","▶","「","」","¥","•","、","。","゛","゜"," ","!","\\\"","#","$","%","&","'","(",")","*","+",",","-",".","/","\\48","\\49","\\50","\\51","\\52","\\53","\\54","\\55","\\56","\\57",":",";","<","=",">","?","@","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","[","\\\\","]","^","_","`","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","{","|","}","~","○","█","▒","🐱","⬇️","░","✽","●","♥","☉","웃","⌂","⬅️","😐","♪","🅾️","◆","…","➡️","★","⧗","⬆️","ˇ","∧","❎","▤","▥","あ","い","う","え","お","か","き","く","け","こ","さ","し","す","せ","そ","た","ち","つ","て","と","な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ","ま","み","む","め","も","や","ゆ","よ","ら","り","る","れ","ろ","わ","を","ん","っ","ゃ","ゅ","ょ","ア","イ","ウ","エ","オ","カ","キ","ク","ケ","コ","サ","シ","ス","セ","ソ","タ","チ","ツ","テ","ト","ナ","ニ","ヌ","ネ","ノ","ハ","ヒ","フ","ヘ","ホ","マ","ミ","ム","メ","モ","ヤ","ユ","ヨ","ラ","リ","ル","レ","ロ","ワ","ヲ","ン","ッ","ャ","ュ","ョ","◜","◝"]
    return "".join(chars[b] for b in bs)

def pack_string(s):
    blob = pack_variant(len(s))
    for c in s:
        blob += pack_byte(ord(c))
    return blob

def to_cart(s,pico_path,carts_path,cart_name,cart_id,cart_code=None, label=None):
    cart="""\
pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- {} data cart
-- @freds72
local data="{}"
local mem=0x3100
for i=1,#data,2 do
    poke(mem,tonum("0x"..sub(data,i,i+1)))
    mem+=1
end
cstore(0, 0, 0x4300, "{}")
"""

    tmp=s[:2*0x2000]
    # swap bytes
    gfx_data = ""
    for i in range(0,len(tmp),2):
        gfx_data = gfx_data + tmp[i+1:i+2] + tmp[i:i+1]
    cart += "__gfx__\n"
    cart += re.sub("(.{128})", "\\1\n", gfx_data, 0, re.DOTALL)

    map_data=s[2*0x2000:2*0x3000]
    if len(map_data)>0:
        cart += "__map__\n"
        cart += re.sub("(.{256})", "\\1\n", map_data, 0, re.DOTALL)

    gfx_props=s[2*0x3000:2*0x3100]
    if len(gfx_props)>0:
        cart += "__gff__\n"
        cart += re.sub("(.{256})", "\\1\n", gfx_props, 0, re.DOTALL)

    # save cart + export cryptic music+sfx part
    sfx_data=s[2*0x3100:2*0x4300]
    cart_filename = "{}_{}.p8".format(cart_name,cart_id)
    cart_path = os.path.join(carts_path,"{}_tmp.p8".format(cart_name))
    with open(cart_path, "w") as f:
        f.write(cart.format(cart_name, sfx_data, cart_filename))
    # run cart
    subprocess.run([os.path.join(pico_path,"pico8"),"-x",os.path.abspath(cart_path)], stdout=PIPE, stderr=PIPE, check=True)

    if cart_code:
        cart = cart_code
        with open(os.path.join(carts_path,cart_filename),"r", encoding='utf-8') as f:
            copy = False
            for line in f:
                line = line.rstrip("\n\r")
                if line in ["__lua__"]:
                    # skip code section
                    copy = False
                elif re.match("__([a-z]+)__",line):
                    # any other section
                    copy = True
                if copy:
                    cart += line
                    cart += "\n"
        with open(os.path.join(carts_path,cart_filename),"w", encoding='utf-8') as f:                   
            f.write(cart)

    # label image
    if label:
        cart = ""
        with open(os.path.join(carts_path,cart_filename),"r", encoding='utf-8') as f:
            cart = f.read()
        
        cart += "\n__label__\n"
        cart += re.sub("(.{128})", "\\1\n", label, 0, re.DOTALL)
        cart += "\n"
        with open(os.path.join(carts_path,cart_filename),"w", encoding='utf-8') as f:                   
            f.write(cart)
    
    os.unlink(cart_path)

def to_multicart(s,pico_path,carts_path,cart_name,boot_code=None,label=None):
  cart_id = 0
  cart_data = ""
  for b in tqdm(s, desc="Generating carts", unit="bytes"):
    cart_data += b
    # full cart?
    if len(cart_data)==2*0x4300:
        to_cart(cart_data, pico_path, carts_path, cart_name, cart_id, cart_code=cart_id==0 and boot_code, label=cart_id==0 and label)
        cart_id += 1
        cart_data = ""
  # remaining data?
  if len(cart_data)!=0:
    to_cart(cart_data, pico_path, carts_path, cart_name, cart_id, cart_code=cart_id==0 and boot_code, label=cart_id==0 and label)
  return cart_id

def pack_release(modname, pico_path, carts_path, all_carts, release, mode="bin"):
    all_carts = list(["{}_{}.p8".format(modname,id) for id in all_carts])

    # entry point
    main_cart = all_carts.pop(0)

    #
    option = ""
    if mode == "html":
        option = "-p fps"
    cmd = " ".join([os.path.join(pico_path,"pico8"),main_cart,"-export","\"{}_{}.{} {} {}\"".format(modname, release, mode,option," ".join(all_carts))])
    print(cmd)
    subprocess.run(cmd, cwd=os.path.join(carts_path), check=True)

    #if mode=="html":
    #    # update html plate
    #    html = ""
    #    with open(os.path.join(carts_path, "fps.html"), "r", encoding='utf-8') as f:
    #        html = f.read()
    #        html = html..replace("##game_label##","{}({})".format(modname, release)).replace("##js_file##","{}_{}.js".format(modname, release))
    #    # ovewrite default plate
    #    with open(os.path.join(carts_path, "{}_{}.html".format(modname, release)), "w", encoding='utf-8') as f:
    #        f.write(html)
    


# read infile and write minified version to outfile
def minify_file(infile, outfile):
    # minifying main
    main_code = ""
    with open(infile, "r", encoding='utf-8') as f:
      main_code = f.read()
    # rules
    minify_rules=[
      (re.compile('---',re.MULTILINE),'==='),
      (re.compile('--\\[\\[.*?\\]\\]',re.DOTALL),''),
      (re.compile('--[ ]*.*$',re.MULTILINE),''),
      (re.compile('^[ \t]*',re.MULTILINE),''),
      (re.compile('[ \t]*$',re.MULTILINE),''),
      (re.compile('\n\s*\n*',re.MULTILINE),'\n'),
      (re.compile('===',re.MULTILINE),'---')
    ]
    for rule in minify_rules:
      main_code = rule[0].sub(rule[1],main_code)
    with open(outfile, "w", encoding='utf-8') as f:
      f.write(main_code)

# de-duplicate 8x8 sprites from the given image
# image must use logical colors (eg. 2 pixels per byte)
def register_sprites(sprites, tex, tex_width, tex_height, max_id=None, hint=None):
  tiles = []
  w,h = tex_width // 8, tex_height // 8
  for j in range(0,h):
    for i in range(0,w):
      data = bytes([])
      for y in range(8):
        # read nimbles
        for x in range(0,8,2):
          # image is using the pico palette (+transparency)
          low = tex[(i*8 + x) + (j*8 + y) * tex_width]
          high = tex[(i*8 + x + 1) + (j*8 + y) * tex_width]
          data += bytes([high|low<<4])
      tileid = 0
      if data in sprites:
        tileid = sprites.index(data)
      else:
        tileid = len(sprites)
        sprites.append(data)   
      if max_id and tileid>max_id:
        msg = "Invalid sprite id: {} max: {}".format(tileid, max_id)
        if hint:
          msg += "\n{}".format(hint)
        raise Exception(msg)
      tiles.append(tileid)
  return tiles