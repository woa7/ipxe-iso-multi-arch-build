IPXEDIR=src
TARGETS=\
	bin/ipxe.lkrn\
	bin/ipxe.kpxe\
	bin/ipxe.usb\
	bin/undionly.kpxe\
	bin/virtio-net.rom\
	bin-x86_64-efi/ipxe.efi\
	bin-x86_64-efi/snponly.efi
ARM_TARGETS=\
	bin-arm32-efi/snp.efi
IPXECONFIGS="" com1 com2
MEM=2560
CPU=-smp 2 -cpu Skylake-Client-noTSX-IBRS
OUT=gtk
MONITOR=stdio
NETMODEL=virtio
WNETMODEL=e1000
#NETOPTS=,ipv4
HOSTFWD=,hostfwd=tcp::2220-:22
NET=-net nic,model=$(NETMODEL),macaddr=$(MAC) -net user$(HOSTFWD)$(NETOPTS)
USB=-usb -device usb-tablet
RNG=-object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0,id=rng0
PARAMS:=
MAIN_SCRIPT=menu.ipxe
BOOTCONFIG=com1
BOOTFILE=ipxe/com1/undionly.kpxe
BOOTFILE_EFI=ipxe/ipxe.efi
BOOTORDER=c
EFI_BIOS=/usr/share/edk2/ovmf/OVMF_CODE.fd
UNAME=$(shell uname -r)
MEMTEST_VERSION=$(shell	awk '/^set memtest_version / { print $$3 }' tools.ipxe)
C32S=hdt menu sysdump
IMGDIR=/opt/img/test
#DISKS=$(IMGDIR)/test.img
DISK1=/dev/vg_work/qemu_test1,format=raw
DISK2=/dev/vg_work/qemu_test2,format=raw
DISKS=$(DISK1)
DISKTMP=/tmp/test1.img
DISKDRV="virtio"
CACHE="none"
#DISKS_FULL_PATH+=$(foreach disk,$(DISKS), $(IMGDIR)/$(disk))
override PARAMS+=$(foreach disk,$(DISKS),-drive file=$(disk),cache=$(CACHE),if=$(DISKDRV))
#override PARAMS+=-option-rom $(IPXEDIR)/bin/virtio-net.rom
CA_TRUST=/usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit

all:	rsync pciids.ipxe

.PHONY:	all clean sigs rsync compile syslinux

clean:
	+make -C sigs clean

sigs:
	+make -C sigs

rsync:	images/modules.cgz sigs
	rsync -avPHC --inplace --delete ./ www.salstar.sk:public_html/boot/ \
	  --exclude='**/.git*' --exclude='**/rsync' --exclude='src' \
	  --exclude='.well-known'
	# to tftp server for dhcp boot
	rsync -avPH --inplace ipxe/*pxe ipxe/com* ipxe/*.efi \
		ftp:/var/lib/tftpboot/ipxe/

TRUST=$(shell find `pwd`/certs/ -name \*.crt -o -name \*.pem | xargs echo $(CA_TRUST) | tr ' ' ',')
compile:	syslinux
	for config in $(IPXECONFIGS); do \
		make -j4 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
			TRUST=$(TRUST) $(TARGETS) $(IPXE_OPTS) \
			CONFIG=$$config $(ARGS) \
			NO_WERROR=1; \
		make -j4 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
			TRUST=$(TRUST) $(ARM_TARGETS) $(IPXE_OPTS) \
			CROSS_COMPILE=arm-linux-gnu- ARCH=arm32 \
			CONFIG=rpi $(ARGS) \
			NO_WERROR=1; \
		for i in $(TARGETS); do \
			cp -av $(IPXEDIR)/$$i ipxe/$$config/; \
		done; \
		cp -av $(IPXEDIR)/bin-arm32-efi/snp.efi \
			ipxe/$$config/arm32.efi; \
		$(IPXEDIR)/util/genfsimg -o ipxe/$$config/ipxe.iso \
			$(IPXEDIR)/bin-x86_64-efi/ipxe.efi \
			$(IPXEDIR)/bin-arm32-efi/snp.efi \
			$(IPXEDIR)/bin/ipxe.lkrn; \
	done

ipxe_clean:
	+make -C $(IPXEDIR) clean distclean

updatesrc:
	cd src; git-update-show

recompile:	updatesrc
	@make compile
	@make

images/modules.cgz: images/pmagic/scripts/*
	cd images/pmagic; \
	find scripts modules | grep -v '/\.git' \
		| cpio --quiet -H newc -o | gzip -9 \
		> ../../$@

#$(IMGDIR)/$(DISKS):
#	qemu-img create $@ 8G

boot:	all
	qemu-kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
		-kernel ipxe/$(BOOTCONFIG)/ipxe.lkrn \
		-monitor $(MONITOR) -display $(OUT) \
		$(NET) \
		$(USB) \
		$(RNG) \
		$(PARAMS) \
		$(ARGS)
	@echo ""

onlyboot:
	qemu-kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
		-kernel ipxe/$(BOOTCONFIG)/ipxe.lkrn \
		-monitor $(MONITOR) -display $(OUT) \
		$(NET) \
		$(USB) \
		$(RNG) \
		$(PARAMS) \
		$(ARGS)
	@echo ""

textboot:
	# ncurses mode
	+make boot OUT=curses MONITOR=vc

stdioboot:
	# no-graphics, monitor on stdio
	@echo "Use CTRL+A + C + ENTER to QEMU monitor."
	+make boot OUT="none -nographic -serial mon:stdio" \
		 MONITOR=vc BOOTCONFIG=""
	reset # reset terminal

wboot:
	+make boot NET="$(NET) -net nic,id=vlan1,model=$(WNETMODEL)"

$(DISKTMP):
	qemu-img create $@ 10g

ramboot:	$(DISKTMP)
	+make boot DISKS=$(DISKTMP),format=raw CACHE=writeback

raidboot:
	+make boot DISKS="$(DISK1) $(DISK2)"

undiboot:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
		-display $(OUT) $(USB) $(RNG) $(PARAMS) $(ARGS)

efiboot:	all
	qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE_EFI) \
		-boot n -bios $(EFI_BIOS) \
		-display $(OUT) $(USB) $(RNG) $(PARAMS) $(ARGS)

efiboot2:	all
	# efi boot with 2 disks for mirror
	+make efiboot DISKS="$(DISK1) $(DISK2)"

ramefiboot:	$(DISKTMP)
	+make efiboot DISKS=$(DISKTMP),format=raw CACHE=writeback

armboot:	all
	qemu-system-arm -M virt -m $(MEM) -device virtio-rng-pci \
		-pflash images/arm32_efi/flash0.img \
		-pflash images/arm32_efi/flash1.img \
		-drive file=fat:rw:ipxe/,format=raw,media=disk \
		-device virtio-net,netdev=n1 -netdev user,id=n1

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
