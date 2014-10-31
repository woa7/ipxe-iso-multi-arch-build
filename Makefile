IPXEDIR=../other/ipxe/src
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
WNETMODEL=e1000
NET=-net nic,model=$(NETMODEL) -net user,hostfwd=tcp::2222-:22
#OPTION_ROM=-option-rom $(IPXEDIR)/bin/virtio-net.rom
USB=-usb -usbdevice tablet
PARAMS:=
MAIN_SCRIPT=menu.ipxe
BOOTFILE=ipxe/com1/undionly.kpxe
UNAME=$(shell uname -r)
MEMTEST_VERSION=$(shell	awk '/^set memtest_version / { print $$3 }' $(MAIN_SCRIPT))
C32S=hdt menu sysdump
IMGDIR=/opt/img/test
DISKS="test.img"
DISKDRV="virtio"
override PARAMS+=$(foreach disk,$(DISKS),-drive file=$(IMGDIR)/$(disk),cache=none,if=$(DISKDRV))

all:	rsync pciids.ipxe

.PHONY:	all clean sigs rsync compile syslinux

clean:
	+make -C sigs clean

sigs:
	+make -C sigs

rsync:	images/modules.cgz sigs
	rsync -avPH --inplace --delete ./ ftp:public_html/boot/ \
	  --exclude='**/.svn' --exclude='**/rsync'
	# to tftp server for dhcp boot
	rsync -avPH --inplace ipxe/*pxe ipxe/com* ftp:/var/lib/tftpboot/ipxe/

TRUST=$(shell find `pwd`/certs/ -name \*.crt -o -name \*.pem | xargs echo | tr ' ' ',')
compile:	syslinux
	for config in "" com1 com2; do \
		make -j1 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
			TRUST=$(TRUST) $(TARGETS) NO_WERROR=1 $(IPXE_OPTS) \
			CONFIG=$$config; \
		for i in $(TARGETS); do \
			cp -a $(IPXEDIR)/$$i ipxe/$$config/; \
		done; \
	done

images/modules.cgz: images/pmagic/scripts/*
	cd images/pmagic; \
	find scripts modules | grep -v '/\.svn' \
		| cpio --quiet -H newc -o | gzip -9 \
		> ../../$@

boot:	all
	qemu-kvm -m $(MEM) -kernel ipxe/com1/ipxe.lkrn -monitor $(MONITOR) \
		$(USB) $(PARAMS) $(OPTION_ROM) $(NET) -display $(OUT) $(ARGS)
	@echo ""

textboot:
	+make boot OUT=curses MONITOR=vc

wboot:
	+make boot NET="$(NET) -net nic,vlan=1,model=$(WNETMODEL) -net user,vlan=1"

undi:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
		-display $(OUT) $(USB) $(PARAMS) $(ARGS)

#freedos:
#	zip /tmp/fd11live.img.zip fd11live.img
#	rsync -avP ./fd11live.img /tmp/fd11live.img.zip \
#		mirror@ftp:/home/ftp/pub/mirrors/freedos/1.1/
#	gzip -c1 fd11live.img | ssh mirror@ftp \
#		dd of=/home/ftp/pub/mirrors/freedos/1.1/fd11live.img.gz

#pciids:	/usr/share/hwdata/pci.ids Makefile
#	awk ' \
#	  /^[0-9a-f]{4}/ { \
#	    vendor=substr($$1,1,4); \
#	    printf "#!ipxe\nset ven/%s\n", $$0 > "pciids/" vendor ".ipxe"; \
#	  } \
#	  /^\t[0-9a-f]{4}/ { \
#	    printf "set dev/%s%s\n", vendor, substr($$0, 2) > "pciids/" vendor ".ipxe" \
#	  } \
#	' $<

pciids.ipxe:	/usr/share/hwdata/pci.ids Makefile
	awk ' \
	  BEGIN { \
	    print "#!ipxe\ngoto $${vendor}$${device} || goto $${vendor} || exit" \
	  } \
	  /^[0-9a-f]{4}/ { \
	    vendor=substr($$1,1,4); \
	    printf ":%s\nset ven %s\nexit\n", vendor, substr($$0,7) \
	  } \
	  /^\t[0-9a-f]{4}/ { \
	    printf ":%s%s\nset dev %s\ngoto %s\n", \
	           vendor, substr($$0, 2, 4), substr($$0, 8), vendor \
	  } \
	' $< > $@

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

#images/memtest:	/boot/elf-memtest86+-$(MEMTEST_VERSION)
#	cp -a $< $@
#	touch $@

syslinux:	memdisk pxelinux.cfg/pci.ids pxelinux.cfg/modules.alias pxelinux.cfg/pxelinux.0 $(C32S:%=pxelinux.cfg/%.c32)
