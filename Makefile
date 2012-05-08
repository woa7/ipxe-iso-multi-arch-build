IPXEDIR=../../c/ipxe/src
TARGETS=\
	bin/ipxe.lkrn\
	bin/ipxe.kpxe\
	bin/ipxe.iso\
	bin/ipxe.usb\
	bin/undionly.kpxe\
	#bin/virtio-net.rom
MEM=768
OUT=sdl
MONITOR=stdio
NETMODEL=virtio
NET=-net nic,model=$(NETMODEL) -net user,hostfwd=tcp::2222-:22
#OPTION_ROM=-option-rom $(IPXEDIR)/bin/virtio-net.rom
PARAMS=-usb -usbdevice tablet -vga cirrus
MAIN_SCRIPT=menu.ipxe
BOOTFILE=ipxe/undionly.kpxe
UNAME=$(shell uname -r)
MEMTEST_VERSION=$(shell	awk '/^set memtest_version / { print $$3 }' $(MAIN_SCRIPT))
C32S=hdt menu sysdump

all:	rsync

.PHONY:	all clean sigs rsync compile syslinux

clean:
	+make -C sigs clean

sigs:
	+make -C sigs

rsync:	images/modules.cgz compile sigs
	rsync -avPH --inplace --delete ./ ftp:public_html/pxe/ \
	  --exclude='**/.svn'
	# to tftp server for dhcp boot
	rsync -avPH --inplace ipxe/*pxe ftp:/var/lib/tftpboot/ipxe/
	cd kickstart; ./rsync

compile:	syslinux
	-make -j1 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
		TRUST=`pwd`/certs/upjs.pem,`pwd`/certs/terena.pem \
		$(TARGETS)
	for i in $(TARGETS); do \
		cp -a $(IPXEDIR)/$$i ipxe/; \
	done

images/modules.cgz: images/pmagic/scripts/*
	cd images/pmagic; \
	find scripts modules | grep -v '/\.svn' \
		| cpio --quiet -H newc -o | gzip -9 \
		> ../../$@

boot:	all
	qemu-kvm -m $(MEM) -kernel ipxe/ipxe.lkrn -monitor $(MONITOR) \
		$(PARAMS) $(OPTION_ROM) $(NET) -display $(OUT) $(ARGS)
	@echo ""

textboot:
	-make boot OUT=curses MONITOR=vc

undi:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) \
		-display $(OUT) $(PARAMS) $(ARGS)

#freedos:
#	zip /tmp/fd11live.img.zip fd11live.img
#	rsync -avP ./fd11live.img /tmp/fd11live.img.zip \
#		mirror@ftp:/home/ftp/pub/mirrors/freedos/1.1/
#	gzip -c1 fd11live.img | ssh mirror@ftp \
#		dd of=/home/ftp/pub/mirrors/freedos/1.1/fd11live.img.gz

pxelinux.cfg/pci.ids:	/usr/share/hwdata/pci.ids
	cp -a $< $@

pxelinux.cfg/modules.pcimap:	/lib/modules/$(UNAME)/modules.pcimap
	cp -a $< $@

pxelinux.cfg/modules.alias:	/lib/modules/$(UNAME)/modules.alias
	cp -a $< $@

pxelinux.cfg/pxelinux.0:	/usr/share/syslinux/pxelinux.0
	cp -a $< $@

pxelinux.cfg/%.c32:	/usr/share/syslinux/%.c32
	cp -a $< $@

memdisk:	/usr/share/syslinux/memdisk
	cp -a $< $@

images/memtest:	/boot/memtest86+-$(MEMTEST_VERSION)
	cp -a $< $@

syslinux:	memdisk images/memtest pxelinux.cfg/pci.ids pxelinux.cfg/modules.pcimap pxelinux.cfg/modules.alias pxelinux.cfg/pxelinux.0 $(C32S:%=pxelinux.cfg/%.c32)
