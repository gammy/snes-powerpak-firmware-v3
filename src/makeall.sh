#!/usr/bin/env bash
set -e
path_out=out/POWERPAK

echo "-- ASSEMBLING SNES POWERPAK SOFTWARE --"

echo "Generating POWERPAK.CFG"
dd status=none if=/dev/zero of=${path_out}/POWERPAK.CFG  bs=512  count=1

echo "Generating LASTGAME.LOG"
dd status=none if=/dev/zero of=${path_out}/LASTGAME.LOG  bs=512  count=1

echo "Generating ERROR.LOG"
dd status=none if=/dev/zero of=${path_out}/ERROR.LOG bs=2K  count=1

#echo -- copying TOPLEVEL.BIT --
#cp TOPLEVEL.BIT out/POWERPAK/TOPLEVEL.BIT

echo "Preparing soundbank"
wine snesmod/smconv.exe -s -o soundbnk "music/parforceritt_b2_downsampled.it"
mv soundbnk.bank soundbnk.bnk

echo -e '[objects]\nbootrom.o' >> bootrom.lnk

echo "Compiling bootrom"
wla-65816 -xo bootrom.asm bootrom.o 

echo "Linking bootrom"
wlalink -rs bootrom.lnk bootrom.sfc

cp bootrom.sfc out/bootrom.sfc
cp bootrom.sfc out/POWERPAK/UPDATE.ROM
rm bootrom.lnk
rm bootrom.o

echo '-- FINISHED! --'
