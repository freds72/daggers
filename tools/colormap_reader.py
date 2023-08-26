from dotdict import dotdict
from PIL import Image, ImageFilter
import argparse
import math

# RGB to pico8 color index
rgb_to_pico8={
  "0x000000":0,
  "0x1d2b53":1,
  "0x7e2553":2,
  "0x008751":3,
  "0xab5236":4,
  "0x5f574f":5,
  "0xc2c3c7":6,
  "0xfff1e8":7,
  "0xff004d":8,
  "0xffa300":9,
  "0xffec27":10,
  "0x00e436":11,
  "0x29adff":12,
  "0x83769c":13,
  "0xff77a8":14,
  "0xffccaa":15,
  "0x291814":128,
  "0x111d35":129,
  "0x422136":130,
  "0x125359":131,
  "0x742f29":132,
  "0x49333b":133,
  "0xa28879":134,
  "0xf3ef7d":135,
  "0xbe1250":136,
  "0xff6c24":137,
  "0xa8e72e":138,
  "0x00b543":139,
  "0x065ab5":140,
  "0x754665":141,
  "0xff6e59":142,
  "0xff9d81":143}

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

# palette from a 16x1 image
def palette_from_png(filename):
  src = Image.open(filename)
  width, height = src.size
  if width*height!=16:
    raise Exception("Palette image: {} invalid size: {}x{} - Palette must be max. 16 pixels".format(filename,width,height))
  # copy to know format
  dst = Image.new("RGB",(width, height),0)
  dst.paste(src)
  # convert to array of rgb integers
  palette = []
  for i in range(16):
    rgb = dst.getpixel((i%width,i//width))      
    palette.append(rgb_to_pico8["0x{:02x}{:02x}{:02x}".format(rgb[0],rgb[1],rgb[2])])
  return palette

# helper class to check or build a new palette
class AutoPalette:  
  # palette: an array of (r,g,b,a) tuples
  def __init__(self, palette=None):
    self.auto = palette is None
    self.palette = palette or []

  def register(self, rgba):
    # invalid color (drop alpha)?
    if "0x{0[0]:02x}{0[1]:02x}{0[2]:02x}".format(rgba) not in rgb_to_pico8:
      raise Exception("Invalid color: {} in image".format(rgba))
    # returns a 0-15 value for image encoding
    if rgba in self.palette: return self.palette.index(rgba)
    # not found and auto-palette
    if self.auto:
      # already full?
      count = len(self.palette)
      if count==16:
        raise Exception("Image uses too many colors (16+). New color: {} not allowed".format(rgba))
      self.palette.append(rgba)
      return count
    raise Exception("Color: {} not in palette".format(rgba))

  # returns a list of hardware colors matching the palette
  # label indicates if color coding should be using 'fake' hexa or standard
  def pal(self, label=False):
    encoding = rgb_to_pico8
    if label:
      encoding = rgb_to_label
    return list(map(encoding.get,map("0x{0[0]:02x}{0[1]:02x}{0[2]:02x}".format,self.palette)))

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

def rgb_distance(e1, e2):
  rmean = ( e1[0] + e2[0] ) / 2
  r = e1[0] - e2[0]
  g = e1[1] - e2[1]
  b = e1[2] - e2[2]
  # return math.sqrt((2+rmean/256)*r*r + 4*g*g + (2+(255-rmean)/256)*b*b)
  return sqr(r) + sqr(g) + sqr(b)

def palette_to_ramp(filename,target_color,ramp_size,ramp_mode,fixed_color=None,keep_palette=False):
  src = Image.open(filename)
  width, height = src.size
  if width*height!=16:
    raise Exception("Palette image: {} invalid size: {}x{} - Palette must be max. 16 pixels".format(filename,width,height))
  # copy to know format
  tmp = Image.new("RGB",(width, height),0)
  tmp.paste(src)
  dst = Image.new("RGB",(16, ramp_size),0)
  # convert to array of rgb integers
  palette = []
  out=[]
  out_row=[]
  for i in range(16):
    rgb = tmp.getpixel((i%width,i//width))    
    hexa = "0x{:02x}{:02x}{:02x}".format(rgb[0],rgb[1],rgb[2])
    if hexa not in rgb_to_pico8:
      raise Exception(f"Unknown color: {hexa} at {(i%width,i//width)}")
    # fill first row
    dst.putpixel((i,0),rgb)
    palette.append(rgb)
    out_row.append(rgb_to_pico8[hexa])
  out.append(";".join(map(str,out_row)))

  # interpolate to target
  std_pico_palette = std_rgb_palette(max_index=256)
  if keep_palette:
    std_pico_palette = {rgb:std_pico_palette[rgb] for rgb in palette}
  pico_to_std_palette = dict(map(reversed, std_pico_palette.items()))
  std_ycc_palette = {p8:rgb_to_ycc(rgba) for p8,rgba in pico_to_std_palette.items()}  
  
  if ramp_mode=="rgb":
    dst_r,dst_g,dst_b = pico_to_std_palette[target_color]
    # skip first line
    for j in range(1,ramp_size):
      ratio = j/(ramp_size-1)
      # ratio = math.pow(ratio, 0.95)
      out_row=[]
      for i in range(16):
        src_r,src_g,src_b = palette[i]
        r,g,b = (lerp(src_r,dst_r,ratio),lerp(src_g,dst_g,ratio),lerp(src_b,dst_b,ratio))         
        diffs = {p8:math.sqrt(sqr((r-rgb[0])) + sqr((g-rgb[1])) + sqr((b-rgb[2]))) for p8,rgb in pico_to_std_palette.items()}
        # diffs = {p8:rgb_distance((r,b,g),rgb) for p8,rgb in pico_to_std_palette.items()}
        best_p8_color = min(diffs, key=diffs.get)
        # replace palette color by p8 hardware color
        out_row.append(best_p8_color)
        dst.putpixel((i,j),pico_to_std_palette[best_p8_color])      
      out.append(";".join(map(str,out_row)))
  elif ramp_mode=="ycc":
    dst_y,dst_cb,dst_cr = rgb_to_ycc(pico_to_std_palette[target_color])
    # skip first line
    for j in range(1,ramp_size):
      ratio = j/(ramp_size-1)
      out_row=[]
      for i in range(16):
        # move to YCC space
        src_y,src_cb,src_cr = rgb_to_ycc(palette[i])
        y,cb,cr = (lerp(src_y,dst_y,ratio),lerp(src_cb,dst_cb,ratio),lerp(src_cr,dst_cr,ratio))
        diffs = {p8:math.sqrt(1.4*sqr(y-ycc[0]) + .8*sqr(cb-ycc[1]) + .8*sqr(cr-ycc[2])) for p8,ycc in std_ycc_palette.items()}
        best_p8_color = min(diffs, key=diffs.get)
        # replace palette color by p8 hardware color
        out_row.append(best_p8_color)
        dst.putpixel((i,j),pico_to_std_palette[best_p8_color])  
      out.append(";".join(map(str,out_row)))
  else:
    raise Exception(f"Uknown interpolation mode: {ramp_mode}")
  
  print("[[{0}]]".format("\n".join(out)))
  dst.save(f"ramp_{target_color}_{ramp_mode}.png",'PNG')

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--palette", required=True, type=str, help="path to palette image")
  parser.add_argument("--ramp", type=int, help="Target color (PICO hw index)")
  parser.add_argument("--ramp-size", type=int, default=16, help="Ramp size (default: 16)")
  parser.add_argument("--ramp-mode", type=str, default="rgb", help="Interpolation space (default: rgb)")
  parser.add_argument("--fixed-color", type=int, default=None, help="Non interpolated color index [0-15]")
  parser.add_argument("--keep", action='store_true', help="Non interpolated color index [0-15]")

  args = parser.parse_args()
  if args.ramp is not None:
    palette_to_ramp(args.palette,args.ramp,args.ramp_size,args.ramp_mode,fixed_color=args.fixed_color,keep_palette=args.keep)
    # animate_ramp(args.palette,args.ramp)
  else:
    print(palette_from_png(args.palette))

if __name__ == '__main__':
  main()

