#ifndef GB_DUMP_RECEIVER__
#define GB_DUMP_RECEIVER__

#define DUMP_OK 0
#define GENERIC_DUMP_ERROR -1
#define SIZE_DUMP_ERROR -2

int read_dump(int);
const u8* get_dump_buffer(void);

#endif