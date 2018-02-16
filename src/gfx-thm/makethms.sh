#!/usr/bin/env bash

for theme in fourdots mario mufasa retrousb simba
do
	echo "Generating ${theme}.THM"
	cat $(ls -1 ${theme}??.bin | sort -n) > ${theme}.THM
done
