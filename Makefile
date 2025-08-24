# STM32F4 Makefile for Renode simulation
TARGET = battery_demo
BUILD_DIR = build

# Toolchain
CC = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
SIZE = arm-none-eabi-size

# MCU settings
MCU = cortex-m4
FPU = -mfpu=fpv4-sp-d16
FLOAT-ABI = -mfloat-abi=soft

# Compiler flags
CFLAGS = -mcpu=$(MCU) -mthumb $(FPU) $(FLOAT-ABI)
C_DEFS = -DSTM32F407xx -DUSE_HAL_DRIVER
C_DEFS += -DMEMFAULT_PROJECT_KEY=\"$(MEMFAULT_PROJECT_KEY)\"
CFLAGS += $(C_DEFS)
CFLAGS += -Wall -Wextra -Og -g3 -gdwarf-2
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -MMD -MP
# Disable problematic FPU optimizations for Renode compatibility
CFLAGS += -fno-builtin

# Linker flags
LDFLAGS = -mcpu=$(MCU) -mthumb $(FPU) $(FLOAT-ABI)
LDFLAGS += -specs=nano.specs -specs=nosys.specs
LDFLAGS += -Wl,--gc-sections -static
LDFLAGS += -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref
LDFLAGS += -T STM32F407VGTx_FLASH.ld

# Memfault SDK paths
MEMFAULT_PORT_ROOT = ../third_party/memfault
MEMFAULT_SDK_ROOT = $(MEMFAULT_PORT_ROOT)/memfault-firmware-sdk
MEMFAULT_COMPONENTS = core util panics metrics

# Memfault Project Key (from environment variable)
ifndef MEMFAULT_PROJECT_KEY
$(error MEMFAULT_PROJECT_KEY environment variable is not set. Please set it with: export MEMFAULT_PROJECT_KEY=your_key_here)
endif

# Include paths
INCLUDES = -I.
INCLUDES += -IInc
INCLUDES += -ICMSIS/Device/ST/STM32F4xx/Include
INCLUDES += -ICMSIS/Include
INCLUDES += -I$(MEMFAULT_SDK_ROOT)/components/include
INCLUDES += -I$(MEMFAULT_SDK_ROOT)/ports/include
INCLUDES += -I$(MEMFAULT_PORT_ROOT)

# Memfault source files
MEMFAULT_SOURCES = $(MEMFAULT_PORT_ROOT)/memfault_platform_port.c
MEMFAULT_SOURCES += $(wildcard $(MEMFAULT_SDK_ROOT)/components/core/src/*.c)
MEMFAULT_SOURCES += $(wildcard $(MEMFAULT_SDK_ROOT)/components/util/src/*.c)
MEMFAULT_SOURCES += $(wildcard $(MEMFAULT_SDK_ROOT)/components/panics/src/*.c)
MEMFAULT_SOURCES += $(wildcard $(MEMFAULT_SDK_ROOT)/components/metrics/src/*.c)

# Source files
C_SOURCES = main.c
C_SOURCES += memfault_cli.c
C_SOURCES += system_stm32f4xx.c
C_SOURCES += $(MEMFAULT_SOURCES)

# Assembly sources
ASM_SOURCES = startup_stm32f407xx.s

# Object files
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))

# VPATH for finding source files in subdirectories
vpath %.c $(sort $(dir $(C_SOURCES)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

# Default target
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin

# Build directory
$(BUILD_DIR):
	mkdir -p $@

# Compile C sources
$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $(INCLUDES) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

# Compile assembly sources
$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) $< -o $@

# Link
$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	$(SIZE) $@

# Generate binary
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf | $(BUILD_DIR)
	$(OBJCOPY) -O binary -S $< $@

# Clean
clean:
	-rm -fR $(BUILD_DIR)

# Flash to Renode (we'll use this to load the binary)
renode: $(BUILD_DIR)/$(TARGET).elf
	@echo "Binary ready for Renode: $(BUILD_DIR)/$(TARGET).elf"
	@echo "Use this in Renode: sysbus LoadELF @$(BUILD_DIR)/$(TARGET).elf"

.PHONY: all clean renode