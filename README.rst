gba-dump-gb
=================

ROM: gba_send_and_receive/gba_send_and_receive.gba

You need to use a GB (or GBC) Link Cable. GBA Link Cables won't work without modifications.

Homebrew which can multiboot another GBA into GBC Dumping mode by pressing START.

It can then get the data from the GBC dumper and put it in its own save file
by pressing SELECT, when the other device is ready.

Supported save formats: SRAM, FLASH-ROM and inside its own ROM (for certain repro-carts).

To build it, you need devkitPro.

The actual GBA ROM can be built using make_sender.ps1.

Technical details
=================

The Dumper (payload.asm) sends "single byte"s in 2 nybble transfers (masked with 0x10),
and it expects to receive the "single byte" it sent during the next "single byte" transfer.
Failing to do so will cause the transfer to restart from a checkpoint at the first occasion
by sending a FAIL. OK and FAIL are masked with 0x40. Details below.

First the GBC payload sends information about the transfer: whether it will be a ROM
one or a SRAM one. After that, it sends the size and does an extra transfer to check
that the receiver got the right size. If all went well, it sends an OK and starts
the actual transfer.

During the transfer, the dumper will send 0x100 "single byte"s and do an extra transfer
to also check the last byte it sent. If all went well, it sends an OK and continues on
to the next batch of 0x100 "single byte"s.

payload2.asm contains a dummy receiver which sends back what it just received.

Credits
=================

Thanks to:

- Dwedit, for the original ROM that tried to enter GBC mode:

  https://www.dwedit.org/dwedit_board/viewtopic.php?id=339

- Extrems, for discovering that the code needs to be in IWRAM to actually work.

- AntonioND, the original gba-switch-to-gbc ROM this has been forked from:

  https://github.com/AntonioND/gba-switch-to-gbc

- ShinyQuagsire, the idea for the project.
  
