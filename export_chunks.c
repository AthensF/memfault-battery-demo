// Simple chunk export function to add to main.c
// This will export Memfault chunks in the proper format

#include "memfault/components.h"
#include <stdio.h>

void export_memfault_chunks(void) {
    // Trigger a heartbeat to ensure we have data
    memfault_metrics_heartbeat_collect_data();
    
    // Try to get chunks from the packetizer
    uint8_t chunk_buffer[1024];
    size_t chunk_len = sizeof(chunk_buffer);
    
    if (memfault_packetizer_get_chunk(chunk_buffer, &chunk_len)) {
        // In a real system, you'd send this over HTTP/UART
        // For now, we'll just indicate we have data
        printf("Chunk available: %zu bytes\n", chunk_len);
        
        // Print as hex for manual inspection
        printf("Chunk data: ");
        for (size_t i = 0; i < chunk_len && i < 64; i++) {
            printf("%02x", chunk_buffer[i]);
        }
        printf("\n");
    } else {
        printf("No chunks available\n");
    }
}
