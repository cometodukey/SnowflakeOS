export # Makes variables from this file available in sub-makefiles

HOST=i686-elf
PREFIX=usr
BOOTDIR=boot
LIBDIR=$(PREFIX)/lib
INCLUDEDIR=$(PREFIX)/include
ISODIR=isodir
ISO=$(PWD)/$(ISODIR)
SYSROOTDIR=sysroot
SYSROOT=$(PWD)/$(SYSROOTDIR)

PATH:=$(PATH):$(PWD)/toolchain/compiler/bin

AR=$(HOST)-ar
AS=$(HOST)-as
LD=$(HOST)-ld
CC=$(HOST)-gcc --sysroot=$(SYSROOT) -isystem=/$(INCLUDEDIR)

CFLAGS=-O2 -std=gnu11 -ffreestanding -Wall -Wextra -Wno-format
LDFLAGS=-nostdlib

# Make will be called on these folders
PROJECTS=libc snow kernel modules

# Generate project sub-targets
PROJECT_HEADERS=$(PROJECTS:=.headers) # appends .headers to every project name
PROJECT_CLEAN=$(PROJECTS:=.clean)

.PHONY: all build qemu bochs clean toolchain $(PROJECTS)

all: build SnowflakeOS.iso

build: $(PROJECTS)

# Copy headers before building anything
$(PROJECTS): $(PROJECT_HEADERS)
	$(MAKE) -C $@ build

# Specify dependencies
kernel: libc
snow: libc
modules: libc snow

qemu: SnowflakeOS.iso
	qemu-system-x86_64 -display sdl -cdrom SnowflakeOS.iso -monitor stdio -s -no-reboot -no-shutdown -serial file:serial.log
	cat serial.log

bochs: SnowflakeOS.iso
	bochs -q -rc .bochsrc_cmds
	cat serial.log

clean: $(PROJECT_CLEAN)
	rm -rfv $(SYSROOTDIR)
	rm -rfv $(ISODIR)
	rm -fv SnowflakeOS.iso
	rm -fv misc/grub.cfg
	rm -fv xbochs.log
	rm -fv irq.log

SnowflakeOS.iso: build misc/grub.cfg
	mkdir -p $(ISODIR)/boot/grub
	cp misc/grub.cfg $(ISODIR)/boot/grub
	grub-mkrescue -o SnowflakeOS.iso $(ISODIR)

misc/grub.cfg: build misc/gen-grub-config.sh
	bash ./misc/gen-grub-config.sh

toolchain:
	cd toolchain; env -i ./build-toolchain.sh

# Automatic rules for our generated sub-targets
%.headers: %/
	$(MAKE) -C $< install-headers

%.clean: %/
	$(MAKE) -C $< clean
