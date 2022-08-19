import sys
max_size = 0x20000

prod = "const uint8_t free_section[FREE_SECTION_SIZE] __attribute__ ((aligned (16))) = {\n    "
for n in range(0, max_size):
    prod += "0x00, "
    if n % 8 == 7:
      prod += "\n    "
prod += "};"
print("#include <gba.h>\n#define FREE_SECTION_SIZE " + str(max_size) + "\n" + prod)