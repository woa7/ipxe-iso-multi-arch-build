IPXEDIR=../../c/ipxe/src
TARGETS=\
	bin/ipxe.lkrn\
	bin/ipxe.kpxe\
	bin/ipxe.iso\
	bin/ipxe.usb\
	bin/undionly.kpxe\
	#bin/virtio-net.rom
MEM=1024
OUT=sdl
MONITOR=stdio
NETMODEL=virtio
NET=-net nic,model=$(NETMODEL) -net user,hostfwd=tcp::2222-:22
#OPTION_ROM=-option-rom $(IPXEDIR)/bin/virtio-net.rom
USB=-usb -usbdevice tablet
PARAMS:=
MAIN_SCRIPT=menu.ipxe
BOOTFILE=ipxe/undionly.kpxe
UNAME=$(shell uname -r)
MEMTEST_VERSION=$(shell	awk '/^set memtest_version / { print $$3 }' $(MAIN_SCRIPT))
C32S=hdt menu sysdump
NON_AUTO_SRCS=\
	#drivers/net/bnx2.c \
	#drivers/net/prism2.c
IMGDIR=/opt/img/test
DISKS="test.img"
override PARAMS+=$(foreach disk,$(DISKS),-drive file=$(IMGDIR)/$(disk),cache=none,if=virtio)

all:	rsync

.PHONY:	all clean sigs rsync compile syslinux

clean:
	+make -C sigs clean

sigs:
	+make -C sigs

rsync:	images/modules.cgz compile sigs
	rsync -avPH --inplace --delete ./ ftp:public_html/boot/ \
	  --exclude='**/.svn' --exclude='**/rsync'
	# to tftp server for dhcp boot
	rsync -avPH --inplace ipxe/*pxe ftp:/var/lib/tftpboot/ipxe/

TRUST=$(shell find `pwd`/certs/ -name \*.crt -o -name \*.pem | tr '\n' ',')
compile:	syslinux
	-make -j1 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
		TRUST=$(TRUST) $(TARGETS) NO_WERROR=1 \
		NON_AUTO_SRCS=$(NON_AUTO_SRCS) $(IPXE_OPTS)
	for i in $(TARGETS); do \
		cp -a $(IPXEDIR)/$$i ipxe/; \
	done
	cp -a $(IPXEDIR)/config/local/*.h ipxe/

images/modules.cgz: images/pmagic/scripts/*
	cd images/pmagic; \
	find scripts modules | grep -v '/\.svn' \
		| cpio --quiet -H newc -o | gzip -9 \
		> ../../$@

boot:	all
	qemu-kvm -m $(MEM) -kernel ipxe/ipxe.lkrn -monitor $(MONITOR) \
		$(USB) $(PARAMS) $(OPTION_ROM) $(NET) -display $(OUT) $(ARGS)
	@echo ""

textboot:
	-make boot OUT=curses MONITOR=vc

undi:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) \
		-display $(OUT) $(USB) $(PARAMS) $(ARGS)

#freedos:
#	zip /tmp/fd11live.img.zip fd11live.img
#	rsync -avP ./fd11live.img /tmp/fd11live.img.zip \
#		mirror@ftp:/home/ftp/pub/mirrors/freedos/1.1/
#	gzip -c1 fd11live.img | ssh mirror@ftp \
#		dd of=/home/ftp/pub/mirrors/freedos/1.1/fd11live.img.gz

pxelinux.cfg/pci.ids:	/usr/share/hwdata/pci.ids
	cp -a $< $@

pxelinux.cfg/modules.pcimap:	/usr/lib/modules/$(UNAME)/modules.pcimap
	cp -a $< $@

pxelinux.cfg/modules.alias:	/usr/lib/modules/$(UNAME)/modules.alias
	cp -a $< $@

pxelinux.cfg/pxelinux.0:	/usr/share/syslinux/pxelinux.0
	cp -a $< $@

pxelinux.cfg/%.c32:	/usr/share/syslinux/%.c32
	cp -a $< $@

memdisk:	/usr/share/syslinux/memdisk
	cp -a $< $@

images/memtest:	/boot/elf-memtest86+-$(MEMTEST_VERSION)
	cp -a $< $@
	touch $@

syslinux:	memdisk pxelinux.cfg/pci.ids pxelinux.cfg/modules.alias pxelinux.cfg/pxelinux.0 $(C32S:%=pxelinux.cfg/%.c32)
