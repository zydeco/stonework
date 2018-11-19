//
//  PBWAddressSpace.h
//  Stonework
//
//  Created by Jesús A. Álvarez on 03/11/2018.
//  Copyright © 2018 namedfork. All rights reserved.
//

#ifndef PBWAddressSpace_h
#define PBWAddressSpace_h

/*
 Emulated address space:
 +------------------+ 0x10000
 | App image        |
 +------------------+ 0x20000
 | RAM globals      | see PBWAddressSpace+Globals.h
 +------------------+ 0x21000
 | RAM heap         |
 +------------------+ 0x2f000
 | RAM stack        |
 +------------------+ 0x30000
 
 +------------------+ 0x40000
 | OS Objects       | Not actually mapped, pointers are tags
 +------------------+ 0x60000
 | API jump table   |
 +------------------+ 0x61000
 
 +------------------+ 0x80000
 | API entry points | (hook_exec)
 +------------------+ 0x81000
 
 */

#define kAppBase 0x10000
#define kAppMaxSize 0x10000
#define kRAMBase 0x20000
#define kRAMSize 0x10000
#define kRAMGlobalsSize 0x1000

/* Stack grows down */
#define kStackTop (kRAMBase + kRAMSize)
#define kStackSize 0x1000
#define kStackBase (kStackTop - kStackSize)

/* Heap grows up */
#define kHeapBase kRAMBase + kRAMGlobalsSize
#define kHeapSize (kRAMSize - (kRAMGlobalsSize + kStackSize))
#define kHeapTop (kHeapBase + kHeapSize)

/* OS Objects */
#define kOSObjectTagBase 0x40000
#define kOSObjectTagTop 0x60000

/* Pebble API */
#define kJumpTableBase 0x60000
#define kJumpTableEntries 1024
#define kJumpTableSize (4 * kJumpTableEntries)
#define kAPIBase 0x80000

/* Round size up to multiple of 4K */
#define pad4K(x) ((x + 4095) & 0xfff000)

#endif /* PBWAddressSpace_h */
