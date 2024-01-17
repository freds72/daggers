from dotdict import dotdict
from PIL import Image, ImageFilter
import argparse
import math
from python2pico import cstore,run_cart

# RGB to pico8 color index
rgb_to_pico8={
  0x000000:0,
  0x1d2b53:1,
  0x7e2553:2,
  0x008751:3,
  0xab5236:4,
  0x5f574f:5,
  0xc2c3c7:6,
  0xfff1e8:7,
  0xff004d:8,
  0xffa300:9,
  0xffec27:10,
  0x00e436:11,
  0x29adff:12,
  0x83769c:13,
  0xff77a8:14,
  0xffccaa:15,
  0x291814:128,
  0x111d35:129,
  0x422136:130,
  0x125359:131,
  0x742f29:132,
  0x49333b:133,
  0xa28879:134,
  0xf3ef7d:135,
  0xbe1250:136,
  0xff6c24:137,
  0xa8e72e:138,
  0x00b543:139,
  0x065ab5:140,
  0x754665:141,
  0xff6e59:142,
  0xff9d81:143}

rgb_to_pico8 = {((rgb&0xff0000)//65536,(rgb&0xff00)//256,rgb&0xff):v for rgb,v in rgb_to_pico8.items()}
pico8_to_rgb = {v:k for k,v in rgb_to_pico8.items()}

# map rgb colors to label fake hexa codes
rgb_to_label={
  "0x000000":'0',
  "0x1d2b53":'1',
  "0x7e2553":'2',
  "0x008751":'3',
  "0xab5236":'4',
  "0x5f574f":'5',
  "0xc2c3c7":'6',
  "0xfff1e8":'7',
  "0xff004d":'8',
  "0xffa300":'9',
  "0xffec27":'a',
  "0x00e436":'b',
  "0x29adff":'c',
  "0x83769c":'d',
  "0xff77a8":'e',
  "0xffccaa":'f',
  "0x291814":'g',
  "0x111d35":'h',
  "0x422136":'i',
  "0x125359":'j',
  "0x742f29":'k',
  "0x49333b":'l',
  "0xa28879":'m',
  "0xf3ef7d":'n',
  "0xbe1250":'o',
  "0xff6c24":'p',
  "0xa8e72e":'q',
  "0x00b543":'r',
  "0x065ab5":'s',
  "0x754665":'t',
  "0xff6e59":'u',
  "0xff9d81":'v'}

# returns pico8 standard palette
def std_palette():
  return {rgb:p8 for rgb,p8 in rgb_to_pico8.items() if p8<16}

def std_rgb_palette(max_index=16):
  return {(int(rgb[2:4],16),int(rgb[4:6],16),int(rgb[6:8],16)):p8 for rgb,p8 in rgb_to_pico8.items() if p8<max_index}

def label_palette():
  return rgb_to_label

class RGBColorSpace():
  # stores a list of rgb colors
  def __init__(self, colors, all_colors = None):
    self.colors = colors
    self.all_colors = all_colors or colors

  # returns distance between 2 colors
  def distance(self,a,b):
    r = a[0] - b[0]
    g = a[1] - b[1]
    b = a[2] - b[2]
    return sqr(r) + sqr(g) + sqr(b)

  def best_match(self,src_idx,dst_idx,ratio):
    src_r,src_g,src_b = self.colors[src_idx]
    dst_r,dst_g,dst_b = self.all_colors[dst_idx]

    r,g,b = (lerp(src_r,dst_r,ratio),lerp(src_g,dst_g,ratio),lerp(src_b,dst_b,ratio))         
    diffs = {i:math.sqrt(sqr((r-rgb[0])) + sqr((g-rgb[1])) + sqr((b-rgb[2]))) for i,rgb in enumerate(self.all_colors)}
    # diffs = {p8:rgb_distance((r,b,g),rgb) for p8,rgb in pico_to_std_palette.items()}
    return min(diffs, key=diffs.get)

# Helper class to handle palette conversions
class Palette:  
  # palette: an array of (r,g,b,a) tuples
  def __init__(self, filename):
    self.alt = {}
    self.alt_rgb = {}
    src = Image.open(filename)
    width, height = src.size
    if width*height!=16:
      raise Exception("Palette image: {} invalid size: {}x{} - Palette must be max. 16 pixels".format(filename,width,height))
    # copy to know format
    dst = Image.new("RGB",(width, height),0)
    dst.paste(src)
    # convert to map of hw index values
    self.hw = bytearray()
    self.rgb = []
    for i in range(16):
      rgb = dst.getpixel((i%width,i//width))      
      hw_idx = rgb_to_pico8.get(rgb,-1)
      if hw_idx==-1:
        raise Exception(f"Unknown RGB: {rgb} in palette at: {(i%width,i//width)}")
      self.rgb.append(rgb)
      self.hw.append(hw_idx)

  def pal(self):
    return self.hw

  # generate color ramp to given color HW code (HW space)
  def screen_fade(self,target_color,ramp_size=16,color_space=RGBColorSpace,scale=1,exclude=[]):
    all_colors = list(rgb_to_pico8.keys())
    color_finder = color_space(self.rgb, all_colors)

    out = bytearray()
    # first line is current color set
    out += self.hw

    # convert to rgb
    target_rgb = pico8_to_rgb[target_color]
    target_rgb_idx = all_colors.index(target_rgb)

    # skip first line    
    for j in range(1,ramp_size):
      ratio = scale * (j/(ramp_size-1))
      for i in range(16):
        if self.hw[i] in exclude:
          best_color = i
        else:
          best_color = color_finder.best_match(i, target_rgb_idx, ratio)
        # replace actual color by p8 hardware color
        out.append(rgb_to_pico8[all_colors[best_color]])
    return out
  
  # load an alternate (logical) palette from file
  def register(self,name,filename):
    src = Image.open(filename)
    width, height = src.size
    if width*height!=16:
      raise Exception("Palette image: {} invalid size: {}x{} - Palette must be max. 16 pixels".format(filename,width,height))
    # copy to known format
    dst = Image.new("RGB",(width, height),0)
    dst.paste(src)
    # find hw colors
    palette = []
    for i in range(16):
      rgb = dst.getpixel((i%width,i//width))
      if rgb not in self.rgb:
        raise Exception(f"Color: {rgb} at {(i%width,i//width)} not registered in palette")
      palette.append(self.hw[self.rgb.index(rgb)])
    self.alt[name] = palette

  # create a color ramp using palette colors (logical space)
  def fade_to(self,target_color,palette=None,ramp_size=16,color_space=RGBColorSpace,scale=1,flip=False):  
    # create a rgb palette  
    palette = self.alt.get(palette, self.hw)
    if target_color not in self.hw:
      raise Exception(f"Target color: {target_color} has not match in HW palette.")
    target_index = self.hw.index(target_color)
    color_finder = color_space([pico8_to_rgb[hw] for hw in palette], self.rgb)

    range_lo,range_hi = 1,0
    if flip: range_lo,range_hi = 0,1
    out=bytearray()
    for j in range(ramp_size):
      ratio = scale * lerp(range_lo,range_hi,j/(ramp_size-1))
      for i in range(16):
        best_color = color_finder.best_match(i, target_index, ratio)
        # color index is in "self.rgb" space
        out.append(best_color)
    return out    

  def animate(self,target_color,palette=None,color_space=RGBColorSpace):
    if target_color not in self.hw:
      raise Exception(f"Target color: {target_color} has not match in HW palette.")

    # generate the fade to black "base" ramp
    ramp = self.fade_to(0,palette=palette,color_space=color_space)

    # create a rgb palette  
    ramp_colors = [self.rgb[i] for i in ramp]
    target_index = self.hw.index(target_color)
    color_finder = color_space(ramp_colors, self.rgb)

    out = bytearray()
    for band in range(16):
      for k in range(16*16):
        k_band = k//16
        ratio = math.pow(max(0,math.cos((band-k_band)*2*math.pi/16)),3)
        
        # dst.putpixel((k%16,k//16),(int(ratio*255), int(ratio*255), int(ratio*255)))
        best_color = color_finder.best_match(k, target_index, ratio)
        out.append(best_color)
    return out
  
def rgb_to_ycc(rgb):
  r,g,b = rgb
  y = 0.299 * r           + 0.587    * g + 0.114    * b
  cb = 128 - 0.168736 * r - 0.331264 * g + 0.5      * b
  cr = 128 + 0.5 * r      - 0.418688 * g - 0.081312 * b
  return (y,cb,cr)

def sqr(x):
  return x *x

def lerp(a,b,t):
  return a*(1-t) + b*t

def animate_ramp(filename,target_color):
  src = Image.open(filename)
  width, height = src.size
  if width*height!=16:
    raise Exception("Palette image: {} invalid size: {}x{} - Palette must be max. 16 pixels".format(filename,width,height))
  # copy to know format
  tmp = Image.new("RGB",(width, height),0)
  tmp.paste(src)

  # convert to array of rgb integers
  palette = []
  
  for i in range(16):
    rgb = tmp.getpixel((i%width,i//width))    
    hexa = "0x{:02x}{:02x}{:02x}".format(rgb[0],rgb[1],rgb[2])
    if hexa not in rgb_to_pico8:
      raise Exception(f"Unknown color: {hexa} at {(i%width,i//width)}")
    palette.append(rgb)
  
  std_pico_palette = std_rgb_palette(max_index=256)
  std_pico_palette = {rgb:std_pico_palette[rgb] for rgb in palette}
  pico_to_std_palette = dict(map(reversed, std_pico_palette.items()))
  rgb_to_pal = {palette[i]:i for i in range(16)}

  def lerp_color(src_rgb,dst_rgb,ratio):
    src_r,src_g,src_b = src_rgb
    dst_r,dst_g,dst_b = dst_rgb
    r,g,b = (lerp(src_r,dst_r,ratio),lerp(src_g,dst_g,ratio),lerp(src_b,dst_b,ratio))
    diffs = {p8:math.sqrt(sqr(r-rgb[0]) + sqr(g-rgb[1]) + sqr(b-rgb[2])) for p8,rgb in pico_to_std_palette.items()}
    return min(diffs, key=diffs.get)

  # skip first line
  dst_rgb = pico_to_std_palette[0]
  for j in range(1,16):
    ratio = j/15
    for i in range(16):
      src_rgb = palette[i]
      best_p8_color = lerp_color(src_rgb, dst_rgb, ratio)
      palette.append(pico_to_std_palette[best_p8_color])

  out = []
  gifs = []
  dst_rgb = pico_to_std_palette[target_color]
  for band in range(16):
    dst = Image.new("RGB",(16,16),0)
    for k in range(16*16):
      k_band = k//16
      ratio = math.pow(max(0,math.cos((band-k_band)*2*math.pi/16)),3)
      
      src_rgb = palette[k]
      # dst.putpixel((k%16,k//16),(int(ratio*255), int(ratio*255), int(ratio*255)))
      best_p8_color = lerp_color(src_rgb, dst_rgb, ratio)
      c = best_p8_color
      if k%16==0: c=0
      dst.putpixel((k%16,k//16),pico_to_std_palette[c])
      out.append(str(rgb_to_pal[pico_to_std_palette[c]]))
    dst.save(f"animated_ramp_{band}.png",'PNG')
    gifs.append(dst)

  gifs[0].save('animated_ramp.gif',save_all=True, append_images=gifs[1:], optimize=False, duration=40, loop=0)
  # 
  print("[[{0}]]".format("\n".join([";".join(out[x:x+16]) for x in range(0, len(out),16)][::-1])))

def squeeze(data):
  bytes = bytearray()
  for i in range(0,len(data),2):
    low = data[i]
    hi = data[i+1]
    assert(low<16)
    assert(hi<16)
    bytes.append(low|hi<<4)
  return bytes

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--palette", required=True, type=str, help="path to palette image (physical colors)")
  parser.add_argument("--shadow-palette", required=True, type=str, help="path to palette image to be for ground shading (logical colors)")
  parser.add_argument("--upgrade-color", type=int, help="clear color (default 10 - green)")
  parser.add_argument("--clear-color", type=int, default=0, help="clear color index (default 0 - black)")
  parser.add_argument("--blink-color", type=int, help="hit color index")
  parser.add_argument("--jewel-color", type=int, help="jewel grab color index")
  parser.add_argument("--ramp-mode", type=str, default="rgb", help="Interpolation space (default: rgb)")
  parser.add_argument("--export", type=str, help="Export image only")
  parser.add_argument("--export-gif", type=str, help="Export animated palette")

  args = parser.parse_args()
  
  # colormaps
  # fade to black - hw colors
  # fade to black - normal  - logical colors
  # fade to black - shadows - logical colors
  # fade to white - logical colors (8 levels)
  # upgrade ramps - logical colors (16 ramps)

  palette_strip = Image.new("RGB",(16, 16*16*2+16*3+8),0)
  out = bytearray()  
  palette = Palette(args.palette)
  global yoffset
  yoffset = 0
  def with_export_to_img(data,pal=lambda i: palette.pal()[i]):
    global yoffset
    for i,idx in enumerate(data):
      rgb = pico8_to_rgb[pal(idx)]
      palette_strip.putpixel((i%16,(i//16 + yoffset)),rgb)
    yoffset += len(data)//16    
    return data

  palette.register("shadows", args.shadow_palette)
  out = with_export_to_img(palette.screen_fade(args.clear_color,ramp_size=12),pal=lambda i:i)
  out += with_export_to_img(palette.screen_fade(args.jewel_color,ramp_size=4,scale=0.8,exclude=[args.clear_color]),pal=lambda i:i)
  # hit palette
  out += squeeze(with_export_to_img(palette.fade_to(args.blink_color,ramp_size=8,scale=0.75,flip=True)))
  # full palette fading + level up
  out += squeeze(with_export_to_img(palette.fade_to(args.clear_color)))
  out += squeeze(with_export_to_img(palette.animate(args.upgrade_color)))
  # ground palette (light/dark) + level up
  out += squeeze(with_export_to_img(palette.fade_to(args.clear_color,palette="shadows")))
  out += squeeze(with_export_to_img(palette.animate(args.upgrade_color, palette="shadows")))

  if args.export:
    tmp = Image.new("RGB",(512, 512),0)
    base = 0
    y = 0
    for i in (12,4,8):
      pals = palette_strip.crop((0,base,16,base+i))
      tmp.paste(pals,(0,y))
      base+=i
      y+=i+2
    tmp.save("tmp.png","PNG")

    pals = palette_strip.crop((0,base,16,base+16))
    tmp.paste(pals,(18,0))
    base += 16+16*16
    pals = palette_strip.crop((0,base,16,base+16))
    tmp.paste(pals,(18,18))

    # animated strips
    base = 12+4+8+16
    for i in range(16):
      pals = palette_strip.crop((0,base+i*16,16,base+(i+1)*16))
      tmp.paste(pals,(36 + i*16,0))

    base += 16*16+16
    for i in range(16):
      pals = palette_strip.crop((0,base+i*16,16,base+(i+1)*16))
      tmp.paste(pals,(36 + i*16,18))
    tmp.save(args.export,"PNG")
  elif args.export_gif:
    gifs = []
    for i in range(16):
      y0 = 12+4+8+16+i*16
      frame = palette_strip.crop((0,y0,16,y0+16)).resize((384,384),resample=Image.Resampling.NEAREST)
      gifs.append(frame)
    gifs[0].save(f'{args.export_gif}',save_all=True, append_images=gifs[1:], optimize=False, duration=40, loop=0)    
  else:
    cstore(out,"D:\\pico-8_0.2.5","..\\carts","freds72_daggers_title",0x0)
    run_cart("D:\\pico-8_0.2.5","..\\carts","title_assets",len(out))

    
if __name__ == '__main__':
  main()

