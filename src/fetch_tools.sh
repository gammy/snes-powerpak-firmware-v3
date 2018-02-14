#!/usr/bin/env bash
# A little helper to get some tools needed to complete the build.

set -e
(
    mkdir tools/ 
    cd tools/

    # pvsneslib contains 'smconv' and 'gfx2snes' 
    if [ ! -e pvsneslib ]
    then
        git clone https://github.com/alekmaul/pvsneslib.git
    fi

    for tool in smconv gfx2snes
    do
        echo "Building $tool"
        (
            cd pvsneslib/tools/${tool}
            # pvsneslib stupidly hardcodes the cross compiler path for their
            # PC. We overwrite the values with our stock compilers
            sed --in-place -e 's/^CC\s=.*/CC = gcc/' Makefile
            sed --in-place -e 's/^CP\s=.*/CP = g++/' Makefile
            make
            cp ${tool}.exe ../../../
        )
    done

    echo "Building pcx2snes"
    # And pcx2snes.. (lazy!)
    curl -O https://raw.githubusercontent.com/gilligan/snesdev/master/tools/pcx2snes/pcx2snes.c
    gcc -o pcx2snes pcx2snes.c
)
