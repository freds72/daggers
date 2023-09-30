import argparse
import subprocess
from python2pico import minify_file

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--pico", required=True, type=str, help="path to pico binary")  
  parser.add_argument("--release", required=True, type=str, help="release name")

  args = parser.parse_args()

  # all game files
  includes = ["main","main_maths","common","polytex","plain","assets"]
  for i in includes:
    minify_file(f"carts/{i}.lua",f"carts/{i}_mini.lua")

  with open("carts/daggers.p8","r") as src:
    src_content = src.read()
    for i in includes:
      src_content = src_content.replace(f"#include {i}.lua","#include {i}_mini.lua")
    with open("carts/daggers_mini.p8","w") as dst:
      dst.write(src_content)

  print("open title.p8 in pico. Execute: ")
  print(f"export daggers_{args.release}.html -f index.html daggers_mini.p8 editor.p8 daggers_assets.p8")

if __name__ == '__main__':
  main()
