#!/bin/bash

../nasm.exe -fbin life.asm -o life.bin
cat.exe ../boot ../pure64-vesa.sys life.bin > project.img
../nasm.exe -fbin floppy.asm -o floppy.img
/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe startvm "pxetest"
#/c/Program\ Files/qemu/qemu-system-x86_64w.exe -boot a -fda project.img
