gba-dump-gb
=================

Routine to switch a GBA into GBC mode by software and to then dump cartridges' contents!

Switch to GBC mode using gba-switch-to-gbc_mb.gba, then properly insert a cartridge
and you'll be able to dump either ROM or SRAM of GB/GBC games.

The results are:

- GBA: It works.
- GBA SP: It works.
- GB Micro: Correct boot ROM animation, with sound. Nintendo logo is white,
  which means the GBC CPU is reading zeroes from the cart instead of data.
- DS: It doesn't work at all. Black screen. I suppose it hangs in the infinite
  loop at the end of the code.
- GB Player: It works.

To build it, you need devkitPro.

The actual GBA ROM can be built using make_sender.ps1.

make_receiver.ps1 will make a dummy receiver which can be used to test the sender.

Technical details
=================

The Dumper sends "single byte"s in 2 nybble transfers (masked with 0x10),
and it expects to receive the "single byte" it sent during the next "single byte" transfer.
Failing to do so will cause the transfer to restart from a checkpoint at the first occasion
by sending a FAIL. OK and FAIL are masked with 0x40. Details below.

First the GBC payload sends information about the transfer: whether it will be a ROM
one or a SRAM one. After that, it sends the size and does an extra transfer to check
that the receiver got the right size. If all went well, it sends an OK and starts
the actual transfer.

During the transfer, the dumper will send 0x100 "single byte"s and, if all went well,
send an OK and continue on to the next batch of 0x100 "single byte"s.

Credits
=================

Thanks to:

- Dwedit, for the original ROM that tried to enter GBC mode:

  https://www.dwedit.org/dwedit_board/viewtopic.php?id=339

- Extrems, for discovering that the code needs to be in IWRAM to actually work.

- AntonioND, the original gba-switch-to-gbc ROM this has been forked from:

  https://github.com/AntonioND/gba-switch-to-gbc

- ShinyQuagsire, the idea for the project.
  
