#!/bin/sh

SERIAL="/dev/ttyUSB1"

sudo picocom "$SERIAL" -b 115200
