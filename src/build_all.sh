#!/usr/bin/env bash
set -e
rm -rf tools/

echo "Fetching tools"
bash fetch_tools.sh

(
    echo "Constructing graphics"
    cd gfx-rom
    bash convert_gfx.sh
) 

echo "Build bootloader"
bash makeall.sh

(
    echo "Build updater"
    cd updater
    bash makeall.sh
)

