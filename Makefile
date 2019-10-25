# Tools

CC ?= gcc
C++ ?= g++
CC_MIPS ?= mips-elf-gcc
AS_MIPS ?= mips-elf-as
LD_MIPS ?= mips-elf-ld

# Compiler

CFLAGS_MIPS = -O3 -Wall -c -s -funroll-loops -mips1 -mtune=mips1 -msoft-float -std=c99 -DVHDL_SIMULATION
ENTRY_LOAD = 0x10000000
ENTRY_HDL = 0x0

# Directories

TOP = .

C = $(TOP)/C
HDL = $(TOP)/HDL
BUILD = $(TOP)/BUILD
SIMULATION = $(TOP)/SIMULATION
SYNTHESIS = $(TOP)/SYNTHESIS
SCRIPTS = $(TOP)/SCRIPTS

PLASMA = $(HDL)/PLASMA
CUSTOM = $(HDL)/CUSTOM
TOOLS = $(C)/tools
OBJ = $(TOP)/OBJ
BIN = $(TOP)/BIN

BUILD_DIRS = $(BIN) $(OBJ)
BUILD_BINS =

# Tools

CONVERT_BIN = $(BIN)/convert_bin
CONVERT_BIN_SOURCES = $(TOOLS)/convert.c
BUILD_BINS += $(BIN)/convert_bin

PROGRAMMER = $(BIN)/programmer
PROGRAMMER_SOURCES = $(TOOLS)/prog_format_for_boot_loader/main.cpp
BUILD_BINS += $(BIN)/programmer

# C

PROJECTS =

SHARED_FILES = no_os.c
SHARED_FILES_ASM = uboot.asm
SHARED_SOURCES = $(addprefix $(C)/shared/,$(SHARED_FILES))
SHARED_SOURCES_ASM = $(addprefix $(C)/shared/,$(SHARED_FILES_ASM))
SHARED_OBJECTS = $(addprefix $(OBJ)/shared/,$(SHARED_FILES:.c=.o))
SHARED_OBJECTS_ASM = $(addprefix $(OBJ)/shared/,$(SHARED_FILES_ASM:.asm=.o))
BUILD_DIRS += $(OBJ)/shared

BOOT_LOADER_HDL = $(BIN)/boot_loader.txt
BOOT_LOADER_FILES = main.c
BOOT_LOADER_SOURCES = $(addprefix $(C)/boot_loader/Sources/,$(BOOT_LOADER_FILES))
BOOT_LOADER_OBJECTS = $(addprefix $(OBJ)/boot_loader/,$(BOOT_LOADER_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/boot_loader

HELLO = $(BIN)/hello.bin
HELLO_HDL = $(BIN)/hello.txt
HELLO_FILES = main.c
HELLO_SOURCES = $(addprefix $(C)/hello/Sources/,$(HELLO_FILES))
HELLO_OBJECTS = $(addprefix $(OBJ)/hello/,$(HELLO_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/hello
BUILD_BINS += $(BIN)/hello.bin
PROJECTS += $(HELLO)

PROJET_E2 = $(BIN)/projet_e2.bin
PROJET_E2_HDL = $(BIN)/projet_e2.txt
PROJET_E2_FILES = main.c
PROJET_E2_SOURCES = $(addprefix $(C)/projet_e2/Sources/,$(PROJET_E2_FILES))
PROJET_E2_OBJECTS = $(addprefix $(OBJ)/projet_e2/,$(PROJET_E2_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/projet_e2
BUILD_BINS += $(BIN)/projet_e2.bin
PROJECTS += $(PROJET_E2)

MANDELBROT = $(BIN)/mandelbrot.bin
MANDELBROT_HDL = $(BIN)/mandelbrot.txt
MANDELBROT_FILES = main.c
MANDELBROT_SOURCES = $(addprefix $(C)/mandelbrot/Sources/,$(MANDELBROT_FILES))
MANDELBROT_OBJECTS = $(addprefix $(OBJ)/mandelbrot/,$(MANDELBROT_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/mandelbrot
BUILD_BINS += $(BIN)/mandelbrot.bin
PROJECTS += $(MANDELBROT)

PGCD = $(BIN)/pgcd.bin
PGCD_HDL = $(BIN)/pgcd.txt
PGCD_FILES = main.c
PGCD_SOURCES = $(addprefix $(C)/pgcd/Sources/,$(PGCD_FILES))
PGCD_OBJECTS = $(addprefix $(OBJ)/pgcd/,$(PGCD_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/pgcd
BUILD_BINS += $(BIN)/pgcd.bin
PROJECTS += $(PGCD)

BUTTONS = $(BIN)/buttons.bin
BUTTONS_HDL = $(BIN)/buttons.txt
BUTTONS_FILES = main.c
BUTTONS_SOURCES = $(addprefix $(C)/buttons/Sources/,$(BUTTONS_FILES))
BUTTONS_OBJECTS = $(addprefix $(OBJ)/buttons/,$(BUTTONS_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/buttons
BUILD_BINS += $(BIN)/buttons.bin
PROJECTS += $(BUTTONS)

RGB_OLED = $(BIN)/rgb_oled.bin
RGB_OLED_HDL = $(BIN)/rgb_oled.txt
RGB_OLED_FILES = main.c
RGB_OLED_SOURCES = $(addprefix $(C)/rgb_oled/Sources/,$(RGB_OLED_FILES))
RGB_OLED_OBJECTS = $(addprefix $(OBJ)/rgb_oled/,$(RGB_OLED_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/rgb_oled
BUILD_BINS += $(BIN)/rgb_oled.bin
PROJECTS += $(RGB_OLED)

SWITCH_LED = $(BIN)/switch_led.bin
SWITCH_LED_HDL = $(BIN)/switch_led.txt
SWITCH_LED_FILES = main.c
SWITCH_LED_SOURCES = $(addprefix $(C)/switch_led/Sources/,$(SWITCH_LED_FILES))
SWITCH_LED_OBJECTS = $(addprefix $(OBJ)/switch_led/,$(SWITCH_LED_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/switch_led
BUILD_BINS += $(BIN)/switch_led.bin
PROJECTS += $(SWITCH_LED)

SEVEN_SEGMENTS = $(BIN)/seven_segments.bin
SEVEN_SEGMENTS_HDL = $(BIN)/seven_segments.txt
SEVEN_SEGMENTS_FILES = main.c
SEVEN_SEGMENTS_SOURCES = $(addprefix $(C)/seven_segments/Sources/,$(SEVEN_SEGMENTS_FILES))
SEVEN_SEGMENTS_OBJECTS = $(addprefix $(OBJ)/seven_segments/,$(SEVEN_SEGMENTS_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/seven_segments
BUILD_BINS += $(BIN)/seven_segments.bin
PROJECTS += $(SEVEN_SEGMENTS)

I2C = $(BIN)/i2c.bin
I2C_HDL = $(BIN)/i2c.txt
I2C_FILES = main.c i2c.c
I2C_SOURCES = $(addprefix $(C)/i2c/Sources/,$(I2C_FILES))
I2C_OBJECTS = $(addprefix $(OBJ)/i2c/,$(I2C_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/i2c
BUILD_BINS += $(BIN)/i2c.bin
PROJECTS += $(I2C)

TSI = $(BIN)/tsi.bin
TSI_HDL = $(BIN)/tsi.txt
TSI_FILES = main.c
TSI_SOURCES = $(addprefix $(C)/tsi/Sources/,$(TSI_FILES))
TSI_OBJECTS = $(addprefix $(OBJ)/tsi/,$(TSI_FILES:.c=.o))
BUILD_DIRS += $(OBJ)/tsi
BUILD_BINS += $(BIN)/tsi.bin
PROJECTS += $(TSI)

# Plasma SoC

PLASMA_SOC = $(BIN)/plasma.bit
PLASMA_SOC_BOOTROM = $(PLASMA)/code_bin.txt
PLASMA_SOC_FLOW = $(OBJ)/plasma/plasma.tcl
PLASMA_CUSTOM_FILES = coproc_1.vhd \
	coproc_2.vhd \
	coproc_3.vhd \
	coproc_4.vhd \
	function_1.vhd \
	function_2.vhd \
	function_3.vhd \
	function_4.vhd \
	function_5.vhd \
	function_6.vhd \
	function_7.vhd \
	function_8.vhd \
	function_9.vhd \
	function_10.vhd \
	function_11.vhd \
	function_12.vhd \
	function_13.vhd \
	function_14.vhd \
	function_15.vhd \
	function_16.vhd \
	function_17.vhd \
	function_18.vhd \
	function_19.vhd 
PLASMA_CUSTOM_SOURCES = $(addprefix $(CUSTOM)/$(CONFIG_PROJECT)/,$(PLASMA_CUSTOM_FILES))
PLASMA_SOC_FILES = alu.vhd \
	bus_mux.vhd \
	cam_pkg.vhd \
	comb_alu_1.vhd \
	control.vhd \
	conversion.vhd \
	dma_engine.vhd \
	mem_ctrl.vhd \
	memory_64k.vhd \
	mlite_cpu.vhd \
	mlite_pack.vhd \
	mult.vhd \
	pc_next.vhd \
	pipeline.vhd \
	plasma.vhd \
	ram_boot.vhd \
	reg_bank.vhd \
	sequ_alu_1.vhd \
	shifter.vhd \
	top_plasma.vhd \
	txt_util.vhd \
	vga_bitmap_160x100.vhd \
	vga_ctrl.vhd \
	vgd_bitmap_640x480.vhd
PLASMA_SOC_SOURCES = $(addprefix $(PLASMA)/,$(PLASMA_SOC_FILES))
PLASMA_SOC_SOURCES += $(PLASMA_CUSTOM_SOURCES)
PLASMA_SOC_TOP = top_plasma

PLASMA_SIMULATION_FLOW = $(OBJ)/plasma/simulation.tcl
PLASMA_SIMULATION_FILES = tbench.vhd txt_util.vhd
PLASMA_SIMULATION_SOURCES = $(addprefix $(PLASMA)/,$(PLASMA_SIMULATION_FILES))
PLASMA_SIMULATION_TOP = tbench
PLASMA_SIMULATION_TCL = $(SIMULATION)/simu_run.tcl

BUILD_DIRS += $(OBJ)/plasma

# Configuration

CONFIG_PROJECT ?= tsi
CONFIG_TARGET ?= nexys4_DDR
CONFIG_PART ?= xc7a100tcsg324-1
CONFIG_SERIAL ?= /dev/ttyUSB1
CONFIG_UART ?= yes
CONFIG_BUTTONS ?= yes
CONFIG_RGB_OLED ?= yes
CONFIG_SWITCH_LED ?= yes
CONFIG_SEVEN_SEGMENTS ?= yes
CONFIG_I2C ?= yes
CONFIG_COPROC ?= yes
CONFIG_VGA ?= no
CONFIG_PWM ?= yes

ifeq ($(CONFIG_PROJECT),hello)
PROJECT = $(HELLO)
PROJECT_HDL = $(HELLO_HDL)
else ifeq ($(CONFIG_PROJECT),projet_e2)
PROJECT = $(PROJET_E2)
PROJECT_HDL = $(PROJET_E2_HDL)
else ifeq ($(CONFIG_PROJECT),mandelbrot)
PROJECT = $(MANDELBROT)
PROJECT_HDL = $(MANDELBROT_HDL)
else ifeq ($(CONFIG_PROJECT),pgcd)
PROJECT = $(PGCD)
PROJECT_HDL = $(PGCD_HDL)
else ifeq ($(CONFIG_PROJECT),buttons)
PROJECT = $(BUTTONS)
PROJECT_HDL = $(BUTTONS_HDL)
else ifeq ($(CONFIG_PROJECT),rgb_oled)
PROJECT = $(RGB_OLED)
PROJECT_HDL = $(RGB_OLED_HDL)
else ifeq ($(CONFIG_PROJECT),switch_led)
PROJECT = $(SWITCH_LED)
PROJECT_HDL = $(SWITCH_LED_HDL)
else ifeq ($(CONFIG_PROJECT),seven_segments)
PROJECT = $(SEVEN_SEGMENTS)
PROJECT_HDL = $(SEVEN_SEGMENTS_HDL)
else ifeq ($(CONFIG_PROJECT),i2c)
PROJECT = $(I2C)
PROJECT_HDL = $(I2C_HDL)
else ifeq ($(CONFIG_PROJECT),tsi)
PROJECT = $(TSI)
PROJECT_HDL = $(TSI_HDL)
endif

PLASMA_SOC_GENERICS =

ifeq ($(CONFIG_UART),yes)
PLASMA_SOC_GENERICS += eUart=1'b1
PLASMA_SOC_FILES += uart.vhd
else
PLASMA_SOC_GENERICS += eUart=1'b0
endif

ifeq ($(CONFIG_BUTTONS),yes)
PLASMA_SOC_GENERICS += eButtons=1'b1
PLASMA_SOC_FILES += buttons.vhd
else
PLASMA_SOC_GENERICS += eButtons=1'b0
endif

ifeq ($(CONFIG_RGB_OLED),yes)
PLASMA_SOC_GENERICS += eRGBOLED=1'b1
PLASMA_SOC_FILES += pmodoledrgb_bitmap.vhd pmodoledrgb_charmap.vhd pmodoledrgb_nibblemap.vhd pmodoledrgb_sigplot.vhd pmodoledrgb_terminal.vhd
else
PLASMA_SOC_GENERICS += eRGBOLED=1'b0
endif

ifeq ($(CONFIG_SWITCH_LED),yes)
PLASMA_SOC_GENERICS += eSwitchLED=1'b1
PLASMA_SOC_FILES += ctrl_SL.vhd
else
PLASMA_SOC_GENERICS += eSwitchLED=1'b0
endif

ifeq ($(CONFIG_SEVEN_SEGMENTS),yes)
PLASMA_SOC_GENERICS += eSevenSegments=1'b1
PLASMA_SOC_FILES += ctrl_7seg.vhd trans_hexto7seg.vhd mux_7seg.vhd mod_7seg.vhd
else
PLASMA_SOC_GENERICS += eSevenSegments=1'b0
endif

ifeq ($(CONFIG_PWM),yes)
PLASMA_SOC_GENERICS += ePWM=1'b1
PLASMA_SOC_FILES += ctrl_pwm.vhd 
else
PLASMA_SOC_GENERICS += ePWM=1'b0
endif

ifeq ($(CONFIG_I2C),yes)
PLASMA_SOC_GENERICS += eI2C=1'b1
PLASMA_SOC_FILES += i2c.vhd
else
PLASMA_SOC_GENERICS += eI2C=1'b0
endif

ifeq ($(CONFIG_COPROC),yes)
PLASMA_SOC_GENERICS += eCoproc=1'b1
#PLASMA_SOC_FILES += $(PLASMA_CUSTOM_SOURCES)
else
PLASMA_SOC_GENERICS += eCoproc=1'b0
endif

ifeq ($(CONFIG_VGA),yes)
PLASMA_SOC_GENERICS += eVGA=1'b1
else
PLASMA_SOC_GENERICS += eVGA=1'b0
endif

PLASMA_SOC_ARGUMENTS = $(foreach generic,$(PLASMA_SOC_GENERICS),-generic $(generic))

TARGET_XDC = $(SYNTHESIS)/$(CONFIG_TARGET).xdc

# Rules

all: plasma project simulation

$(BUILD_DIRS):
	@mkdir -p $@

$(CONVERT_BIN): $(CONVERT_BIN_SOURCES) | $(BUILD_DIRS)
	$(CC) -o $@ $<

.PHONY: convert_bin
convert_bin: $(CONVERT_BIN)

$(PROGRAMMER): $(PROGRAMMER_SOURCES) | $(BUILD_DIRS)
	$(C++) -std=c++11 -o $@ $<

.PHONY: programmer
programmer: $(PROGRAMMER)

.PHONY: send
send: $(PROGRAMMER) $(PROJECT)
	$(PROGRAMMER) $(PROJECT) $(CONFIG_SERIAL)

.PHONY: flash
flash: $(PLASMA_SOC)
	openocd -f $(SCRIPTS)/nexys4-ddr.cfg  -c "init; jtagspi_init 0 $<;"

$(SHARED_OBJECTS): $(OBJ)/shared/%.o: $(C)/shared/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(SHARED_OBJECTS_ASM): $(OBJ)/shared/%.o: $(C)/shared/%.asm | $(BUILD_DIRS)
	$(AS_MIPS) -o $@ $<

$(BOOT_LOADER_OBJECTS): $(OBJ)/boot_loader/%.o: $(C)/boot_loader/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(BOOT_LOADER_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BOOT_LOADER_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/boot_loader/boot_loader_hdl.map -s -N -o $(OBJ)/boot_loader/boot_loader_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BOOT_LOADER_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/boot_loader/boot_loader_hdl.axf $(OBJ)/boot_loader/boot_loader_hdl.bin $(OBJ)/boot_loader/boot_loader_hdl.txt
	cp $(OBJ)/boot_loader/boot_loader_hdl.txt $@

.PHONY: boot_loader
boot_loader: $(BOOT_LOADER_HDL)

$(HELLO_OBJECTS): $(OBJ)/hello/%.o: $(C)/hello/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(HELLO): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(HELLO_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/hello/hello.map -s -N -o $(OBJ)/hello/hello.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(HELLO_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/hello/hello.axf $(OBJ)/hello/hello.bin $(OBJ)/hello/hello.txt
	cp $(OBJ)/hello/hello.bin $@

$(HELLO_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(HELLO_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/hello/hello_hdl.map -s -N -o $(OBJ)/hello/hello_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(HELLO_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/hello/hello_hdl.axf $(OBJ)/hello/hello_hdl.bin $(OBJ)/hello/hello_hdl.txt
	cp $(OBJ)/hello/hello_hdl.txt $@

.PHONY: hello
hello: $(PROJET_E2) $(PROJET_E2_HDL)

$(PROJET_E2_OBJECTS): $(OBJ)/projet_e2/%.o: $(C)/projet_e2/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(PROJET_E2): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PROJET_E2_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/projet_e2/projet_e2.map -s -N -o $(OBJ)/projet_e2/projet_e2.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PROJET_E2_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/projet_e2/projet_e2.axf $(OBJ)/projet_e2/projet_e2.bin $(OBJ)/projet_e2/projet_e2.txt
	cp $(OBJ)/projet_e2/projet_e2.bin $@

$(PROJET_E2_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PROJET_E2_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/projet_e2/projet_e2.map -s -N -o $(OBJ)/projet_e2/projet_e2_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PROJET_E2_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/projet_e2/projet_e2_hdl.axf $(OBJ)/projet_e2/projet_e2_hdl.bin $(OBJ)/projet_e2/projet_e2_hdl.txt
	cp $(OBJ)/projet_e2/projet_e2_hdl.txt $@

.PHONY: projet_e2
projet_e2: $(PROJET_E2) $(PROJET_E2_HDL)

$(PGCD_OBJECTS): $(OBJ)/pgcd/%.o: $(C)/pgcd/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(PGCD): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PGCD_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/pgcd/pgcd.map -s -N -o $(OBJ)/pgcd/pgcd.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PGCD_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/pgcd/pgcd.axf $(OBJ)/pgcd/pgcd.bin $(OBJ)/pgcd/pgcd.txt
	cp $(OBJ)/pgcd/pgcd.bin $@

$(PGCD_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PGCD_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/pgcd/pgcd_hdl.map -s -N -o $(OBJ)/pgcd/pgcd_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(PGCD_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/pgcd/pgcd_hdl.axf $(OBJ)/pgcd/pgcd_hdl.bin $(OBJ)/pgcd/pgcd_hdl.txt
	cp $(OBJ)/pgcd/pgcd_hdl.txt $@

.PHONY: pgcd
pgcd: $(pgcd) $(PGCD_HDL)

$(MANDELBROT_OBJECTS): $(OBJ)/mandelbrot/%.o: $(C)/mandelbrot/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(MANDELBROT): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(MANDELBROT_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/mandelbrot/mandelbrot.map -s -N -o $(OBJ)/mandelbrot/mandelbrot.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(MANDELBROT_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/mandelbrot/mandelbrot.axf $(OBJ)/mandelbrot/mandelbrot.bin $(OBJ)/mandelbrot/mandelbrot.txt
	cp $(OBJ)/mandelbrot/mandelbrot.bin $@

$(MANDELBROT_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(MANDELBROT_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/mandelbrot/mandelbrot_hdl.map -s -N -o $(OBJ)/mandelbrot/mandelbrot_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(MANDELBROT_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/mandelbrot/mandelbrot_hdl.axf $(OBJ)/mandelbrot/mandelbrot_hdl.bin $(OBJ)/mandelbrot/mandelbrot_hdl.txt
	cp $(OBJ)/mandelbrot/mandelbrot_hdl.txt $@

.PHONY: mandelbrot
mandelbrot: $(MANDELBROT) $(MANDELBROT_HDL)

$(BUTTONS_OBJECTS): $(OBJ)/buttons/%.o: $(C)/buttons/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(BUTTONS): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BUTTONS_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/buttons/buttons.map -s -N -o $(OBJ)/buttons/buttons.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BUTTONS_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/buttons/buttons.axf $(OBJ)/buttons/buttons.bin $(OBJ)/buttons/buttons.txt
	cp $(OBJ)/buttons/buttons.bin $@

$(BUTTONS_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BUTTONS_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/buttons/buttons_hdl.map -s -N -o $(OBJ)/buttons/buttons_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(BUTTONS_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/buttons/buttons_hdl.axf $(OBJ)/buttons/buttons_hdl.bin $(OBJ)/buttons/buttons_hdl.txt
	cp $(OBJ)/buttons/buttons_hdl.txt $@

.PHONY: buttons
buttons: $(BUTTONS) $(BUTTONS_HDL)

$(RGB_OLED_OBJECTS): $(OBJ)/rgb_oled/%.o: $(C)/rgb_oled/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(RGB_OLED): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(RGB_OLED_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/rgb_oled/rgb_oled.map -s -N -o $(OBJ)/rgb_oled/rgb_oled.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(RGB_OLED_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/rgb_oled/rgb_oled.axf $(OBJ)/rgb_oled/rgb_oled.bin $(OBJ)/rgb_oled/rgb_oled.txt
	cp $(OBJ)/rgb_oled/rgb_oled.bin $@

$(RGB_OLED_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(RGB_OLED_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/rgb_oled/rgb_oled_hdl.map -s -N -o $(OBJ)/rgb_oled/rgb_oled_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(RGB_OLED_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/rgb_oled/rgb_oled_hdl.axf $(OBJ)/rgb_oled/rgb_oled_hdl.bin $(OBJ)/rgb_oled/rgb_oled_hdl.txt
	cp $(OBJ)/rgb_oled/rgb_oled_hdl.txt $@

.PHONY: rgb_oled
rgb_oled: $(RGB_OLED) $(RGB_OLED_HDL)

$(SWITCH_LED_OBJECTS): $(OBJ)/switch_led/%.o: $(C)/switch_led/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(SWITCH_LED): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SWITCH_LED_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/switch_led/switch_led.map -s -N -o $(OBJ)/switch_led/switch_led.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SWITCH_LED_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/switch_led/switch_led.axf $(OBJ)/switch_led/switch_led.bin $(OBJ)/switch_led/switch_led.txt
	cp $(OBJ)/switch_led/switch_led.bin $@

$(SWITCH_LED_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SWITCH_LED_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/switch_led/switch_led_hdl.map -s -N -o $(OBJ)/switch_led/switch_led_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SWITCH_LED_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/switch_led/switch_led_hdl.axf $(OBJ)/switch_led/switch_led_hdl.bin $(OBJ)/switch_led/switch_led_hdl.txt
	cp $(OBJ)/switch_led/switch_led_hdl.txt $@

.PHONY: switch_led
switch_led: $(SWITCH_LED) $(SWITCH_LED_HDL)

$(SEVEN_SEGMENTS_OBJECTS): $(OBJ)/seven_segments/%.o: $(C)/seven_segments/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(SEVEN_SEGMENTS): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SEVEN_SEGMENTS_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/seven_segments/seven_segments.map -s -N -o $(OBJ)/seven_segments/seven_segments.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SEVEN_SEGMENTS_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/seven_segments/seven_segments.axf $(OBJ)/seven_segments/seven_segments.bin $(OBJ)/seven_segments/seven_segments.txt
	cp $(OBJ)/seven_segments/seven_segments.bin $@

$(SEVEN_SEGMENTS_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SEVEN_SEGMENTS_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/seven_segments/seven_segments_hdl.map -s -N -o $(OBJ)/seven_segments/seven_segments_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(SEVEN_SEGMENTS_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/seven_segments/seven_segments_hdl.axf $(OBJ)/seven_segments/seven_segments_hdl.bin $(OBJ)/seven_segments/seven_segments_hdl.txt
	cp $(OBJ)/seven_segments/seven_segments_hdl.txt $@

.PHONY: seven_segments
seven_segments: $(SEVEN_SEGMENTS) $(SEVEN_SEGMENTS_HDL)

$(I2C_OBJECTS): $(OBJ)/i2c/%.o: $(C)/i2c/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(I2C): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(I2C_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/i2c/i2c.map -s -N -o $(OBJ)/i2c/i2c.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(I2C_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/i2c/i2c.axf $(OBJ)/i2c/i2c.bin $(OBJ)/i2c/i2c.txt
	cp $(OBJ)/i2c/i2c.bin $@

$(I2C_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(I2C_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/i2c/i2c_hdl.map -s -N -o $(OBJ)/i2c/i2c_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(I2C_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/i2c/i2c_hdl.axf $(OBJ)/i2c/i2c_hdl.bin $(OBJ)/i2c/i2c_hdl.txt
	cp $(OBJ)/i2c/i2c_hdl.txt $@

.PHONY: i2c
tsi: $(I2C) $(I2C_HDL)

$(TSI_OBJECTS): $(OBJ)/tsi/%.o: $(C)/tsi/Sources/%.c | $(BUILD_DIRS)
	$(CC_MIPS) $(CFLAGS_MIPS) -o $@ $<

$(TSI): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(TSI_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_LOAD) -eentry -Map $(OBJ)/tsi/tsi.map -s -N -o $(OBJ)/tsi/tsi.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(TSI_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/tsi/tsi.axf $(OBJ)/tsi/tsi.bin $(OBJ)/tsi/tsi.txt
	cp $(OBJ)/tsi/tsi.bin $@

$(TSI_HDL): $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(TSI_OBJECTS) $(CONVERT_BIN) | $(BUILD_DIRS)
	$(LD_MIPS) -Ttext $(ENTRY_HDL) -eentry -Map $(OBJ)/tsi/tsi_hdl.map -s -N -o $(OBJ)/tsi/tsi_hdl.axf $(SHARED_OBJECTS_ASM) $(SHARED_OBJECTS) $(TSI_OBJECTS)
	$(CONVERT_BIN) $(OBJ)/tsi/tsi_hdl.axf $(OBJ)/tsi/tsi_hdl.bin $(OBJ)/tsi/tsi_hdl.txt
	cp $(OBJ)/tsi/tsi_hdl.txt $@

.PHONY: tsi
tsi: $(TSI) $(TSI_HDL)

.PHONY: project
project: $(PROJECT) $(PROJECT_HDL)

.PHONY: projects
projects: $(PROJECTS)

$(PLASMA_SOC): $(PLASMA_SOC_SOURCES) $(BOOT_LOADER_HDL) | $(BUILD_DIRS)
	cp $(BOOT_LOADER_HDL) $(PLASMA_SOC_BOOTROM)
	echo "" > $(PLASMA_SOC_FLOW)
	echo "set outputDir $(OBJ)/plasma" >> $(PLASMA_SOC_FLOW)
	for file in $(PLASMA_SOC_SOURCES); do echo "read_vhdl $$file" >> $(PLASMA_SOC_FLOW); done
	echo "read_xdc $(TARGET_XDC)" >> $(PLASMA_SOC_FLOW)
	echo "synth_design -top $(PLASMA_SOC_TOP) -part $(CONFIG_PART) $(PLASMA_SOC_ARGUMENTS)" >> $(PLASMA_SOC_FLOW)
	echo "opt_design" >> $(PLASMA_SOC_FLOW)
	echo "place_design" >> $(PLASMA_SOC_FLOW)
	echo "phys_opt_design" >> $(PLASMA_SOC_FLOW)
	echo "route_design" >> $(PLASMA_SOC_FLOW)
	echo "write_bitstream -force $@" >> $(PLASMA_SOC_FLOW)
	echo "quit" >> $(PLASMA_SOC_FLOW)
	vivado -source $(PLASMA_SOC_FLOW) -mode tcl -nolog -nojournal
	rm $(PLASMA_SOC_FLOW)

.PHONY: plasma
plasma: $(PLASMA_SOC)

.PHONY: bitstream
bitstream: plasma

.PHONY: vhdl
vhdl: plasma

.PHONY: simulation
simulation: $(PLASMA_SOC_SOURCES) $(PROJECT_HDL) | $(BUILD_DIRS)
	cp $(PROJECT_HDL) $(PLASMA_SOC_BOOTROM)
	echo "" > $(PLASMA_SIMULATION_FLOW)
	for file in $(PLASMA_SOC_SOURCES); do echo "vhdl work ../../$$file" >> $(PLASMA_SIMULATION_FLOW); done
	for file in $(PLASMA_SIMULATION_SOURCES); do echo "vhdl work ../../$$file" >> $(PLASMA_SIMULATION_FLOW); done
	xelab --nolog --debug wave -prj $(PLASMA_SIMULATION_FLOW) -s plasma $(PLASMA_SIMULATION_TOP)
	xsim plasma --nolog --gui -t $(PLASMA_SIMULATION_TCL)
	rm $(PLASMA_SIMULATION_FLOW)
	rm output.txt
	rm -rf xelab* webtalk* xsim*


.PHONY: clean
clean:
	rm -rf $(BUILD_DIRS)
	rm -f $(BUILD_BINS)
	rm -rf xelab* xsim* webtalk* usage_statistics* *.wdb vivado_*
