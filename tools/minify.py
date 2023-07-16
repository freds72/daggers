import argparse
from python2pico import minify_file

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--i", required=True, type=str, help="file to minify")
  parser.add_argument("--o", required=True, type=str, help="output path")

  args = parser.parse_args()
  minify_file(args.i,args.o)

if __name__ == '__main__':
  main()
