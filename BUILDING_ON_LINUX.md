# Requirements

You'll need a number of tools to build this project:

* wla-65816, wlalink: Compiler / Linker (http://www.villehelin.com/wla.html)
* smconv: Music format converter      (https://github.com/alekmaul/pvsneslib.git)
* gfx2snes: Graphics format converter (https://github.com/alekmaul/pvsneslib.git)
* pcx2snes: Grahpics format converter (https://github.com/gilligan/snesdev)

Your linux distribution might have some of these packages available. If not,
I wrote a little shellscript (placed in `src/`) called `fetch_tools.sh` which
pulls and builds everything required.

# Building

It should be as easy as 
```
cd src/
./build_all.sh
```

This will
* Download the tools mentioned above, except for `wla`
* Try to compile the components we need
* Run the graphics construction script
* Build the bootloader
* Build the updater
