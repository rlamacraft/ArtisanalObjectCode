# ArtisanalObjectCode
A simple virtual machine, and some hand-crafted object code

## What does it do?
When run by the virtual machine, the object code reads two 16-bit hexadecimal numbers and sums them

## Files

### lc3.c
Slightly amended version of the virtual machine [tutorial by Justin Meiners and Ryan Pendleton](https://justinmeiners.github.io/lc3-vm/)
To compile, run
```
gcc lc3.c -o lc3.o
```

#### CLI flags
`-d`: Prints out debug information before executing each command
`-s`: Sleeps for 1 second between executing each command

### code.obj
The handwritten object code that runs on the virtual machine
To execute, run
```
./lc3.o code.obj
```

### code.asm
My pseudo-assembly that is used for planning out and documenting the object code
