import argparse
import re
from PIL import Image
from colormap_reader import AutoPalette

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--label", required=True, type=str, help="path to label image")

  args = parser.parse_args()
  src = Image.open(args.label)
  
  # check allowed size  
  size = src.size
  if size!=(128,128):
    raise Exception("Image: {} invalid size: {} - Must be between 128x128".format(args.label, size))

  img = Image.new('RGBA', size, (0,0,0,0))
  img.paste(src)
  p = AutoPalette()

  data = bytearray()
  for y in range(img.size[1]):
    for x in range(0,img.size[0],2):
      low = p.register(img.getpixel((x, y)))
      high = p.register(img.getpixel((x + 1,y)))
      data.append(low)
      data.append(high)
  
  pal = p.pal(label=True)
  label = "".join([pal[c] for c in data])

  cart = "\n__label__\n"
  cart += re.sub("(.{128})", "\\1\n", label, 0, re.DOTALL)
  cart += "\n"
  print(cart)
  
if __name__ == '__main__':
  main()