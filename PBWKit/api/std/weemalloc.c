#include <inttypes.h>
#include <stdio.h>
#include <assert.h>
#include <strings.h>
#include "weemalloc.h"

#ifdef DEBUGG
#define debug_print(args ...) printf(args)
#else
#define debug_print(args ...) do { if (0) printf(args); } while (0)
#endif

// internal functions
void weemalloc_defragment_freelist(void *heap, uint32_t ptr);
uint32_t weemalloc_alloc_block(void *hptr, uint32_t block_offset, uint32_t alloc_size);

struct __attribute__((packed)) weemalloc_heap {
    uint32_t size;
    uint32_t freelist;
};

struct __attribute__((packed)) weemalloc_block {
    uint32_t prev;
    uint32_t size;
    uint32_t next; // only on free blocks
};

#define weemalloc_block(base, offset) (offset ? ((struct weemalloc_block*)((uintptr_t)base + offset)) : NULL)

#define WEEMALLOC_MIN_SIZE 16
#define WEEMALLOC_HEADER_SIZE 8
#define WEEMALLOC_BLOCK_HEADER_SIZE 8

void weemalloc_init(void *hptr, uint32_t size) {
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    heap->size = size;
    heap->freelist = WEEMALLOC_HEADER_SIZE;
    struct weemalloc_block *block = weemalloc_block(hptr, WEEMALLOC_HEADER_SIZE);
    block->prev = 0;
    block->size = size - WEEMALLOC_HEADER_SIZE;
    block->next = 0;
}

uint32_t weemalloc_alloc_block(void *hptr, uint32_t block_offset, uint32_t alloc_size) {
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    struct weemalloc_block *block = weemalloc_block(heap, block_offset);
    if (block->size - alloc_size >= WEEMALLOC_MIN_SIZE) {
        // split block
        uint32_t new_block_offset = block_offset + alloc_size;
        debug_print("<- splitting block 0x%04x to 0x%04x\n", block_offset, new_block_offset);
        struct weemalloc_block *new_block = weemalloc_block(heap, new_block_offset);
        new_block->prev = block->prev;
        new_block->size = block->size - alloc_size;
        new_block->next = block->next;
        if (block->next) {
            struct weemalloc_block *next = weemalloc_block(heap, block->next);
            next->prev = new_block_offset;
        }
        if (block->prev) {
            struct weemalloc_block *prev = weemalloc_block(heap, block->prev);
            prev->next = new_block_offset;
        }
        if (block_offset == heap->freelist) {
            heap->freelist = new_block_offset;
        }
        block->next = 0xffffffff;
        block->size = alloc_size;
        return block_offset + WEEMALLOC_BLOCK_HEADER_SIZE;
    } else {
        // use block
        debug_print("<- using block 0x%04x\n", block_offset);
        struct weemalloc_block *prev = weemalloc_block(heap, block->prev);
        struct weemalloc_block *next = weemalloc_block(heap, block->next);
        if (prev) prev->next = block->next;
        if (next) next->prev = block->prev;
        if (block_offset == heap->freelist) {
            heap->freelist = block->next ?: block->prev;
        }
        block->next = 0xffffffff;
        return block_offset + WEEMALLOC_BLOCK_HEADER_SIZE;
    }
}

uint32_t weemalloc(void *hptr, uint32_t size) {
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    uint32_t alloc_size = (WEEMALLOC_BLOCK_HEADER_SIZE + size + 0xf) & ~0xf;
    debug_print("ALLOC(%2$d): need %1$d\n", alloc_size, size);
    
    // find big enough free block
    uint32_t block_offset = heap->freelist;
    if (heap->freelist == 0) {
        debug_print("  freelist is empty!!!\n");
        return 0;
    }
    struct weemalloc_block *block = weemalloc_block(heap, block_offset);
    while(block->size < alloc_size && block->next) {
        debug_print("  checking 0x%04x", block_offset);
        block_offset = block->next;
        block = weemalloc_block(heap, block_offset);
    }
    
    if (block->size < alloc_size) {
        debug_print("<- no block big enough found.\n");
        return 0;
    };
    
    return weemalloc_alloc_block(hptr, block_offset, alloc_size);
}

uint32_t weecalloc(void *heap, uint32_t count, uint32_t size) {
    uint32_t ptr = weemalloc(heap, count * size);
    if (ptr) bzero(heap + ptr, count * size);
    return ptr;
}

uint32_t weerealloc(void *hptr, uint32_t ptr, uint32_t size) {
    if (ptr == 0) return 0;
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    uint32_t block_offset = ptr - WEEMALLOC_BLOCK_HEADER_SIZE;
    struct weemalloc_block *block = weemalloc_block(heap, block_offset);
    uint32_t alloc_size = (WEEMALLOC_BLOCK_HEADER_SIZE + size + 0xf) & ~0xf;
    debug_print("REALLOC(%3$d, %2$d): need %1$d\n", alloc_size, size, ptr);
    if (block->size >= alloc_size) {
        // block is big enough
        debug_print("  block is big enough\n");
        return ptr;
    }
    
    // check if next block is free
    uint32_t it = heap->freelist;
    while (it && it < block_offset) {
        it = weemalloc_block(heap, it)->next;
    }
    struct weemalloc_block *next = weemalloc_block(heap, it);
    if ((it == (block_offset + block->size)) && ((block->size + next->size) >= alloc_size)) {
        // next block is free and big enough
        debug_print("  next block is free, and big enough\n");
        uint32_t tmp_ptr = weemalloc_alloc_block(hptr, it, alloc_size - block->size);
        block->size += weemalloc_block(heap, tmp_ptr - WEEMALLOC_BLOCK_HEADER_SIZE)->size;
        return ptr;
    }
    
    // allocate new block, copy and free old block
    debug_print("  have to allocate new block!\n");
    uint32_t new_ptr = weemalloc(hptr, size);
    if (new_ptr == 0) return 0;
    void *old_buf = hptr + ptr;
    void *new_buf = hptr + new_ptr;
    memcpy(new_buf, old_buf, block->size);
    weefree(hptr, ptr);
    return new_ptr;
}

void weefree(void *hptr, uint32_t ptr) {
    if (ptr == 0) return;
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    uint32_t block_offset = ptr - WEEMALLOC_BLOCK_HEADER_SIZE;
    struct weemalloc_block *block = weemalloc_block(heap, ptr - WEEMALLOC_BLOCK_HEADER_SIZE);
    debug_print("FREE(0x%04x): block 0x%04x\n", ptr, block_offset);
    if (heap->freelist == 0) {
        // freelist is empty, make this block the freelist
        debug_print("  freelist was empty!\n");
        heap->freelist = block_offset;
        block->prev = 0;
        block->next = 0;
        return;
    }
    // find place in freelist
    uint32_t it = heap->freelist;
    uint32_t tail = 0; 
    while (it && it < block_offset) {
        debug_print("  skipping 0x%04x\n", it);
        tail = it;
        it = weemalloc_block(heap, it)->next;
    }
    if (it == 0) {
        // no next empty block, add to end of freelist
        debug_print("  add to tail\n");
        struct weemalloc_block *prev = weemalloc_block(heap, tail);
        prev->next = block_offset;
        block->prev = tail;
        block->next = 0;
        weemalloc_defragment_freelist(hptr, block_offset);
        return;
    }
    debug_print("  found next empty block: 0x%04x\n", it);
    
    struct weemalloc_block *next = weemalloc_block(heap, it);
    struct weemalloc_block *prev = weemalloc_block(heap, next->prev);
    if (prev) prev->next = block_offset;
    block->prev = next ? next->prev : 0;
    if (next) next->prev = block_offset;
    block->next = it;
    
    if (it == heap->freelist) {
        heap->freelist = block_offset;
    }
    
    weemalloc_defragment_freelist(hptr, block_offset);
}

void weemalloc_get_stats(void *hptr, struct weemalloc_stats *stats) {
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    uint32_t block_offset = WEEMALLOC_HEADER_SIZE;
    uint32_t next_free_block = heap->freelist;
    uint32_t free_size = 0;
    uint32_t free_blocks = 0;
    uint32_t free_max = 0;
    uint32_t used_size = 0;
    uint32_t used_blocks = 0;
    struct weemalloc_block *block;
    while(block_offset < heap->size) {
        block = weemalloc_block(heap, block_offset);
        if (block_offset == next_free_block) {
            // block is free
            next_free_block = block->next;
            free_size += block->size;
            if (free_max < block->size) {
                free_max = block->size;
            }
            free_blocks++;
        } else {
            // block is used
            used_size += block->size;
            used_blocks++;
        }
        block_offset += block->size;
    }
    stats->heap_size = heap->size;
    stats->free_size = free_size;
    stats->free_blocks = free_blocks;
    stats->free_max = free_max;
    stats->used_size = used_size;
    stats->used_blocks = used_blocks;
}

void weemalloc_defragment_freelist(void *hptr, uint32_t block_offset) {
    struct weemalloc_heap* heap = (struct weemalloc_heap*)hptr;
    struct weemalloc_block *block = weemalloc_block(heap, block_offset);
    struct weemalloc_block *prev = weemalloc_block(heap, block->prev);
    struct weemalloc_block *next = weemalloc_block(heap, block->next);
    if (next && (block_offset + block->size == block->next)) {
        // merge with next block
        debug_print("  merging free block with next\n");
        block->size += next->size;
        block->next = next->next;
        if (block->next) {
            weemalloc_block(heap, block->next)->prev = block_offset;
        }
    }
    if (prev && (block->prev + prev->size == block_offset)) {
        // merge with previous block
        debug_print("  merging free block with previous\n");
        prev->size += block->size;
        prev->next = block->next;
        if (block->next) {
            weemalloc_block(heap, block->next)->prev = block->prev;
        }
    }
}

void weemalloc_print_stats(void *hptr, FILE *fd) {
    fprintf(fd, "Heap at %p:\n", hptr);
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    fprintf(fd, "  Size: 0x%1$x (%1$d)\n", heap->size);
    fprintf(fd, "  Freelist: 0x%04x\n", heap->freelist);
    uint32_t block_offset = WEEMALLOC_HEADER_SIZE;
    struct weemalloc_block *block;
    while(block_offset < heap->size) {
        block = weemalloc_block(heap, block_offset);
        fprintf(fd, "  0x%04x: prev=0x%04x,size=%d",
            block_offset,
            block->prev, 
            block->size);
        if (block->next == 0xffffffff) {
            fprintf(fd, " allocated\n");
        } else {
            fprintf(fd, ",next=0x%04x\n", block->next);
        }
        block_offset += block->size;
    }
    fprintf(fd, "--\n");
}

#if __has_extension(blocks)
void weemalloc_foreach_block(void *hptr, void (^f)(uint32_t blockID, uint32_t blockPtr, uint32_t prev, uint32_t blockSize, uint32_t next, int isFree)) {
    struct weemalloc_heap *heap = (struct weemalloc_heap*)hptr;
    uint32_t block_offset = WEEMALLOC_HEADER_SIZE;
    uint32_t next_free_block = heap->freelist;
    struct weemalloc_block *block;
    while(block_offset < heap->size) {
        block = weemalloc_block(heap, block_offset);
        int isFree = 0;
        if (block_offset == next_free_block) {
            isFree = 1;
            next_free_block = block->next;
        }
        f(block_offset, block_offset + WEEMALLOC_BLOCK_HEADER_SIZE, block->prev, block->size, block->next, isFree);
        block_offset += block->size;
    }
}
#endif
