cd source/gbc_payload
make
cd ..
python gbc_payload/convert_to_c.py gbc_payload/payload.gbc > payload_array.h
cd ..
make
rm source/payload_array.h