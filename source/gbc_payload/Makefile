AS := .\rgbasm
ASFLAGS := -i inc/ -i data/ -o
LD := .\rgblink
LDFLAGS2 := -x -o

cgb_src := $(wildcard *.asm)
cgb_rom := $(cgb_src:.asm=.gbc)

all:	$(cgb_rom)

%.gbc: %.o
		$(LD) $(LDFLAGS2) $@ $<

%.o: %.asm
		$(AS) $(ASFLAGS) $@ $<

clean:
		rm -f *.o
		rm -f *.gbc
