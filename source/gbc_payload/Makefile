AS := .\rgbasm
ASFLAGS := -i inc/ -i data/ -o
LD := .\rgblink
LDFLAGS1 := -x -d -o
LDFLAGS2 := -x -o
FX := .\rgbfix
FXFLAGS1 := -p 0 -r 0 -t DMG_EXAMPLE -v
FXFLAGS2 := -C -p 0 -r 0 -t CGB_EXAMPLE -v

cgb_src := $(wildcard *.asm)
cgb_rom := $(cgb_src:.asm=.gbc)

all:	$(cgb_rom)

%.gb: %.o
		$(LD) $(LDFLAGS1) $@ $<
		$(FX) $(FXFLAGS1) $@

%.gbc: %.o
		$(LD) $(LDFLAGS1) $@ $<
		$(FX) $(FXFLAGS1) $@

%.o: %.asm
		$(AS) $(ASFLAGS) $@ $<

clean:
		rm -f *.o
		rm -f *.gbc
