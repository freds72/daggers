import argparse
import subprocess
from python2pico import minify_file

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--pico", required=True, type=str, help="path to pico binary")  
  parser.add_argument("--release", required=True, type=str, help="release name")

  args = parser.parse_args()

  minify_file("carts/main.lua","carts/main_mini.lua")

  with open("carts/daggers.p8","r") as src:
    src_content = src.read().replace("#include main.lua","#include main_mini.lua")
    with open("carts/daggers_mini.p8","w") as dst:
      dst.write(src_content)

  print("open title.p8 in pico. Execute: ")
  print(f"export daggers_{args.release}.html -f index.html daggers_mini.p8 editor.p8 daggers_assets.p8")

if __name__ == '__main__':
  main()
