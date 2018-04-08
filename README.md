# Simplified bootloader for DragonBoard 410c

DragonBoard 410c is a single-board computer based on Qualcomm Snapdragon 410 SoC.
The Apps Bootloader is open-source based on LK. This is an experiment to remove 
some features of the original bootloader, and add custom features to the taste 
of specific projects.

## Boot process of Snapdragon 410c

ROM -> Qualcomm SBL -> Apps Bootloader -> Linux/Android

## Summary of customizations

- Removed other platforms that are not Dragonboard 410c (APQ8016)
- Removed openssl & signature check of the linux kernel binary
- Removed graphics support
- Removed unclear apps

- Change of behavior: Always boot in fastboot mode when there is a micro USB connected.
- Change of behavior: Blink board LEDs when in bootloader mode

- Change of code organization: Simplified makefile
- Change of code organization: Simplified signlk script

- Added feature: More than one USB device interface descriptor. On the future will support USB serial device for bootloader

## How to build

You need a Linux Ubuntu host. Have a look at bootloader_tool.sh

## Contact author

- Victor Pecanins <vpecanins@arroweurope.com>

