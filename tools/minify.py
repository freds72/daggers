import argparse
import os
import subprocess
import sys
from subprocess import Popen, PIPE
from python2pico import minify_file

def run_cart(args):
  process = subprocess.Popen(" ".join(args), stdout=subprocess.PIPE)
  for c in iter(lambda: process.stdout.read(1), b""):
    sys.stdout.buffer.write(c)

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--pico", required=True, type=str, help="path to pico binary")  
  parser.add_argument("--release", required=True, type=str, help="release name")

  args = parser.parse_args()

  # create version cart
  with open(os.path.join("carts","version.p8l"), "w", encoding='UTF-8') as src:
    src.write(f'_version="{args.release.upper()}"')

  # refresh built-in data assets
  # create tmp cart
  with open(os.path.join("carts","freds72_daggers_assets.p8"), "r", encoding='UTF-8') as src: 
    cart = []
    while line := src.readline():
      line = line.rstrip('\n')
      if line == "__gfx__":
        cart.append("""__lua__
-- !!!auto-generated: do not edit!!!                  
local mem=0x0
mem+=4
local version,n=@mem,@(mem+1)
assert(version==1,"unknown/invalid version: "..version)
mem+=2
for i=1,n do
  -- read string
  local k=@mem
  mem+=1
  -- read data
  local len=peek2(mem)
  mem+=2
  mem+=len
end

cstore(0,0,mem,"freds72_daggers_editor.p8")
""")
      cart.append(line)

  tmp_file = os.path.join("carts","temp_assets.p8")
  with open(tmp_file,"w", encoding='UTF-8') as dst:
    dst.write("\n".join(cart))

  run_cart([os.path.join(args.pico,"pico8"),"-home",".","-x","carts/temp_assets.p8"])
  os.unlink(tmp_file)
      
  # game files
  game_files = ["freds72_daggers_title","freds72_daggers","freds72_daggers_editor"]
  for game_file in game_files:
    with open(f"carts/{game_file}.p8", "r", encoding='UTF-8') as src: 
      cart = []
      while line := src.readline():
        line = line.rstrip('\n')
        if "#include" in line:
          # get file
          _,include = line.split(" ")
          if include.endswith(".p8l"):
            release_file = include.replace(".p8l","_release.p8l")
            if os.path.exists(os.path.join("carts",release_file)):
              print(f"Using relase data: {include} --> {release_file}")
              line = f"#include {release_file}"
          else:
            mini_file = include.replace(".lua","_mini.lua")
            print(f"Minifying: {include}  --> {mini_file}")
            minify_file(f"carts/{include}",f"carts/{mini_file}")
            line = f"#include {mini_file}"
        cart.append(line)
      # export minified cart
      with open(f"carts/{game_file}_mini.p8", "w", encoding='UTF-8') as dst:
        dst.write("\n".join(cart))

  print("BINARY EXPORTS")

  print("Manual steps: ")
  print("load freds72_daggers_title_mini.p8")
  print(f"export daggers_{args.release}.html -p fps.html freds72_daggers_mini.p8 freds72_daggers_editor_mini.p8")

  print("BBS EXPORTS")
  try:
    os.mkdir(os.path.join("carts",args.release))
  except FileExistsError:
    pass
  for game_file in game_files:
    run_cart([os.path.join(args.pico,"pico8"),"-home",".",f"carts/{game_file}_mini.p8","-export",f"carts/{args.release}/{game_file}_mini.p8.png"])

if __name__ == '__main__':
  main()
