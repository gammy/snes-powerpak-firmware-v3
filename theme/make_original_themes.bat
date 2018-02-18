@echo off

echo
echo "This script will build ManuLöwe's original themes."
echo "Use 'buildscripts/build_theme' to build new ones (i.e 'gammy')"
echo

set themes=fourdots mario mufasa retrousb simba
for %x in (%themes%) do copy /b /y %%x\%%x??.bin src\out\POWERPAK\THEMES\%%x.THM

pause
