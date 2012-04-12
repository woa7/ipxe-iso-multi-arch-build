IPXEDIR=../../c/ipxe/src
TARGETS=bin/ipxe.lkrn bin/ipxe.kpxe bin/ipxe.iso bin/ipxe.usb bin/undionly.kpxe
MEM=768
NETMODEL=virtio
NET=-net nic,model=$(NETMODEL) -net user,hostfwd=tcp::2222-:22
USB=-usb -usbdevice tablet
BOOTFILE=ipxe/ipxe.kpxe
UNAME=$(shell uname -r)
C32S=hdt menu sysdump

all:	images/modules.cgz compile sigs rsync

.PHONY:	all sigs rsync compile c32s

rsync:	images/modules.cgz compile
	rsync -avPH --inplace --delete ./ ftp:public_html/pxe/ \
	  --exclude='**/.svn'
	# to tftp server for dhcp boot
	rsync -avPH --inplace ipxe/ipxe.* ftp:/var/lib/tftpboot/ipxe/

sigs:
	make -C sigs

compile:	c32s
	make -j1 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
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

test:	all
	qemu-kvm -m $(MEM) -kernel ipxe/ipxe.lkrn $(USB) $(NET) $(ARGS)

undi:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) $(USB) $(ARGS)

#freedos:
#	zip /tmp/fd11live.img.zip fd11live.img
#	rsync -avP ./fd11live.img /tmp/fd11live.img.zip \
#		mirror@ftp:/home/ftp/pub/mirrors/freedos/1.1/
#	gzip -c1 fd11live.img | ssh mirror@ftp \
#		dd of=/home/ftp/pub/mirrors/freedos/1.1/fd11live.img.gz

pci.ids:	/usr/share/hwdata/pci.ids
	cp -a $< $@

modules.pcimap:	/lib/modules/$(UNAME)/modules.pcimap
	cp -a $< $@

modules.alias:	/lib/modules/$(UNAME)/modules.alias
	cp -a $< $@

pxelinux.0:	/usr/share/syslinux/pxelinux.0
	cp -a $< $@

pxelinux.cfg/%.c32:	/usr/share/syslinux/%.c32
	cp -a $< $@

c32s:	pci.ids modules.pcimap modules.alias pxelinux.0 $(C32S:%=pxelinux.cfg/%.c32)
