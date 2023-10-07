import argparse
import os
import subprocess
from subprocess import Popen, PIPE
from python2pico import minify_file

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--pico", required=True, type=str, help="path to pico binary")  
  parser.add_argument("--release", required=True, type=str, help="release name")

  args = parser.parse_args()

  # game files
  game_files = ["freds72_daggers_title","freds72_daggers"]
  for game_file in game_files:
    with open(f"carts/{game_file}.p8","r") as src: 
      cart = []
      for line in src.readlines():
        if "#include" in line:
          # get file
          _,include = line.split(" ")
          mini_file = include.replace(".lua","_mini.lua")
          minify_file(f"carts/{include}",f"carts/{mini_file}")
          line = f"#include {mini_file}"
        cart.append(line)
      # export minified cart
      with open("carts/{game_file}_mini.p8","w") as dst:
        dst.write("\n".join(cart))

  print("BINARY EXPORTS")
  print("open freds72_daggers_title_mini.p8 in pico. Execute: ")
  print(f"export daggers_{args.release}.html -f index.html freds72_daggers_mini.p8 freds72_daggers_editor.p8")

  print("BBS EXPORTS")
  for game_file in game_files:
    subprocess.run([os.path.join(args.pico,"pico8"),"-home",".",f"{game_file}_mini.p8","-export",f"{game_file}_mini.p8.png"], stdout=PIPE, stderr=PIPE, check=True)
  subprocess.run([os.path.join(args.pico,"pico8"),"-home",".",f"freds72_daggers_editor.p8","-export",f"freds72_daggers_editor_mini.p8.png"], stdout=PIPE, stderr=PIPE, check=True)

if __name__ == '__main__':
  main()
