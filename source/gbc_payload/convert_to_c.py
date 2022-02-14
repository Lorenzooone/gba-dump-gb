import sys
from functools import partial

if len(sys.argv) < 2:
  sys.exit('Usage: %s file' % sys.argv[0])
prod = "const uint8_t gbc_payload[PAYLOAD_SIZE] = {\n    "
n = 0
with open(sys.argv[1], "rb") as in_file:
  for c in iter(partial(in_file.read, 1), b''):
    prod += "0x%02X, " % ord(c)
    n += 1
    if n % 8 == 0:
      prod += "\n    "
    if n == 0x1000:
      break
prod += "};"
print("#include <gba.h>\n#define PAYLOAD_SIZE " + str(n) + "\n" + prod)