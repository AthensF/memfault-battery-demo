#include "memfault/components.h"

// Simple CLI-style hook to trigger chunk export on demand.
// You can call this from GDB:
//   (gdb) p export_data_cli_command(0, 0)
__attribute__((used))
int export_data_cli_command(int argc, char *argv[]) {
  (void)argc;
  (void)argv;
  memfault_data_export_dump_chunks();
  return 0;
}

// Example periodic task you can schedule from elsewhere if desired
void some_periodic_task(void) {
  memfault_data_export_dump_chunks();
}
