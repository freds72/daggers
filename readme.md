# DEMI DAGGERS
A Devil's Daggers demake for PICO-8

# How to adjust palette

Command prompt
Run
    cd tools
    python .\colormap_reader.py --palette .\palette.png --shadow-palette .\palette_floor.png --upgrade-color 138 --clear-color 0 --blink-color 137 --jewel-color 7

# How To Release

Open command prompt
CD to repo
Run

    python tools/minify.py --pico <path to pico> --release <relase name>

Example (Windows)

    python .\tools\minify.py --pico D:\pico-8_0.2.5\ --release v1.0

Will generate the minified files for release + BBS carts (png files) into carts/<release> folder 

> note: html export doesn't work, follow script instructions :/

# How to convert GIF

> pre-requisite: ffmpeg

    ffmpeg -f gif -i <in>.gif -vf scale=1024:1024:flags=neighbor -pix_fmt yuv420p <out>.mp4

# Horde animation code

in main.lua:

    do_async(function()
      wait_async(90)
      grid_register(inherit{
        origin={512,16,512-128},
        radius=48,
        apply=nop        
      })
      while true do
        for i=-4,5 do
          local s=make_skull(_skull1_template,{512+8*i,rnd"24",512+200})
          s.min_velocity=0.8
          wait_async(5)
        end
        wait_async(10)
      end
    end)

    do_async(function()
        -- skull 1+2 circle around player
        _skull_base_template.target={512,0,512-196}       
      end)
    end 