cd switch_to_dump/source/gbc_payload
make
cd ..
python gbc_payload/convert_to_c.py gbc_payload/payload.gbc 4096 1 > gbc_payload_array.h
cd ..
make
rm source/gbc_payload_array.h
python source/gbc_payload/convert_to_c.py switch_to_dump_mb.gba -1 1 > ../gba_send_and_receive/source/gba_payload_array.h
cd ../gba_send_and_receive
python source/generate_blank_section.py > source/free_section.h
make
rm source/gba_payload_array.h
rm source/free_section.h
cd ..