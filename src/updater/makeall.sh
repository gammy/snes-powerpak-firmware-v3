#!/usr/bin/env bash

echo Assembling SIv1.MAP
echo -e "[objects]\nsiv1.o\n" > siv1.lnk
wla-65816 -o siv1.asm siv1.o
wlalink -rs siv1.lnk siv1.sfc
head -c 5120 siv1.sfc > ../out/POWERPAK/SIv1.MAP

echo Assembling SIv2.MAP
echo -e "[objects]\nsiv2.o\n" > siv2.lnk
wla-65816 -o siv2.asm siv2.o
wlalink -rs siv2.lnk siv2.sfc
head -c 5120 siv2.sfc > ../out/POWERPAK/SIv2.MAP

rm *.o *.lnk *.sfc *.sym
