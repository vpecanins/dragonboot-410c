-include local.mk
include make/macros.mk

PROJECT := msm8916

# setup toolchain prefix
TOOLCHAIN_PREFIX ?= ../arm-eabi-4.8/bin/arm-eabi-
CC := $(TOOLCHAIN_PREFIX)gcc
LD := $(TOOLCHAIN_PREFIX)ld
STRIP := $(TOOLCHAIN_PREFIX)strip
OBJDUMP := $(TOOLCHAIN_PREFIX)objdump
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
CPPFILT := $(TOOLCHAIN_PREFIX)c++filt
SIZE := $(TOOLCHAIN_PREFIX)size
NM := $(TOOLCHAIN_PREFIX)nm

CPPFLAGS := -fno-exceptions -fno-rtti -fno-threadsafe-statics
#CPPFLAGS += -Weffc++
ASMFLAGS := -DASSEMBLY
LDFLAGS := 

DEBUG ?= 0

LK_TOP_DIR:= .
BUILDDIR := ./build-$(PROJECT)
OUTBIN := $(BUILDDIR)/lk.bin
OUTELF := $(BUILDDIR)/lk.elf
OUTELF_STRIP := $(BUILDDIR)/lk_stripped.elf

CONFIGHEADER := $(BUILDDIR)/config.h

ENABLE_TRUSTZONE := 0

INCLUDES := -I$(BUILDDIR) -Iinclude
CFLAGS := -O2 -g -fno-builtin -finline -W -Wall -Wno-multichar -Wno-unused-parameter -Wno-unused-function -include $(CONFIGHEADER)
#CFLAGS += -Werror
CFLAGS += -D_EMMC_BOOT=1

CFLAGS += -DBUILD_VERSION='"$(shell if git rev-parse --git-dir > /dev/null 2>&1; then git describe --dirty | sed 's/\./_/g'; else echo 'unknown'; fi )"'

CFLAGS += -fstack-protector-all -fno-strict-overflow -ffunction-sections -fdata-sections -fno-short-enums

LDFLAGS += -gc-sections
	
# comment out or override if you want to see the full output of each command
#NOECHO ?= @

# these need to be filled out by the project/target/platform rules.mk files
TARGET :=
PLATFORM :=
ARCH :=
ALLMODULES :=
MODULES :=


# the following three object lists are identical except for the ordering
# which is bootobjs, kobjs, objs
BOOTOBJS :=	
OBJS :=

# a linker script needs to be declared in one of the project/target/platform files
LINKER_SCRIPT := 			

# anything you add here will be deleted in make clean
GENERATED := $(CONFIGHEADER)

# anything added to DEFINES will be put into $(BUILDDIR)/config.h
DEFINES := LK=1				

# Anything added to SRCDEPS will become a dependency of every source file in the system.
# Useful for header files that may be included by one or more source files.
SRCDEPS := $(CONFIGHEADER)



# project defines target
# target defines platform
# platform defines arch
include project/$(PROJECT).mk


include target/$(TARGET)/rules.mk



include platform/$(PLATFORM)/rules.mk


include arch/$(ARCH)/rules.mk
include platform/rules.mk
include kernel/rules.mk
include app/rules.mk


all: build-msm8916/lk_stripped.elf


# recursively include any modules in the MODULE variable, leaving a trail of included
# modules in the ALLMODULES list
include make/module.mk


ALLOBJS := \
	$(BOOTOBJS) \
	$(OBJS)

# add some automatic configuration defines
DEFINES += \
	BOARD=$(PROJECT) \
	PROJECT_$(PROJECT)=1 \
	TARGET_$(TARGET)=1 \
	PLATFORM_$(PLATFORM)=1 \
	ARCH_$(ARCH)=1 \
	$(addsuffix =1,$(addprefix WITH_,$(ALLMODULES)))

# debug build?
ifneq ($(DEBUG),)
DEFINES += \
	DEBUG=$(DEBUG)
endif

ALLOBJS := $(addprefix $(BUILDDIR)/,$(ALLOBJS))

DEPS := $(ALLOBJS:%o=%d)

# TARGETS

# the logic to compile and link stuff is in here
include make/build.mk


nuke:
	rm -rf build-*
	
clean:
	rm -f $(ALLOBJS) $(DEPS) $(GENERATED) $(OUTBIN) $(OUTELF) $(OUTELF).lst $(OUTELF_STRIP)
	


# generate a config.h file with all of the DEFINES laid out in #define format
configheader:

$(CONFIGHEADER): configheader
	@$(MKDIR)
	@echo generating $@
	@rm -f $(CONFIGHEADER).tmp; \
	echo \#ifndef __CONFIG_H > $(CONFIGHEADER).tmp; \
	echo \#define __CONFIG_H >> $(CONFIGHEADER).tmp; \
	for d in `echo $(DEFINES) | tr [:lower:] [:upper:]`; do \
		echo "#define $$d" | sed "s/=/\ /g;s/-/_/g;s/\//_/g" >> $(CONFIGHEADER).tmp; \
	done; \
	echo \#endif >> $(CONFIGHEADER).tmp; \
	if [ -f "$(CONFIGHEADER)" ]; then \
		if cmp "$(CONFIGHEADER).tmp" "$(CONFIGHEADER)"; then \
			rm -f $(CONFIGHEADER).tmp; \
		else \
			mv $(CONFIGHEADER).tmp $(CONFIGHEADER); \
		fi \
	else \
		mv $(CONFIGHEADER).tmp $(CONFIGHEADER); \
	fi

# Empty rule for the .d files. The above rules will build .d files as a side
# effect. Only works on gcc 3.x and above, however.
%.d:

ifeq ($(filter $(MAKECMDGOALS), clean), )
-include $(DEPS)
endif

.PHONY: configheader

print-%  : ; @echo $* = $($*)
	
