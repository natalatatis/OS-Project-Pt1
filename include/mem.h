#ifndef MEM_H
#define MEM_H

#define PUT32(addr,val) (*(volatile unsigned int *)(addr) = (val))
#define GET32(addr) (*(volatile unsigned int *)(addr))

#endif