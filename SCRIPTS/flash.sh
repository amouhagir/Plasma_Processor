#!/bin/sh

CFG="nexys4-ddr.cfg"
BITSTREAM="plasma.bit"
PROJECT="hello"
BINARY="$PROJECT.bin"
SERIAL="/dev/ttyUSB1"

sudo openocd -f "$CFG"  -c "init; jtagspi_init 0 $BITSTREAM;"
echo -n "Reset CPU now! "
read reset
sudo ../Plasma/BIN/programmer "$BINARY" "$SERIAL"
