#include <inttypes.h>

struct weemalloc_stats {
    uint32_t heap_size; // total heap size
    uint32_t free_size; // total bytes that can be allocated
    uint32_t free_blocks; // number of free blocks
    uint32_t free_max; // maximum size that can be allocated
    uint32_t used_size; // total bytes allocated
    uint32_t used_blocks; // number of used blocks
};

void weemalloc_init(void *heap, uint32_t size);
uint32_t weemalloc(void *heap, uint32_t size);
uint32_t weecalloc(void *heap, uint32_t count, uint32_t size);
uint32_t weerealloc(void *heap, uint32_t ptr, uint32_t size);
void weefree(void *heap, uint32_t ptr);
void weemalloc_print_stats(void *heap, FILE *fd);
void weemalloc_get_stats(void *heap, struct weemalloc_stats *stats);
