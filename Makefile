# sudo apt install hwdata syslinux-common pxelinux gcc-arm-none-eabi p11-kit ca-certificates
# sudo /usr/sbin/update-ca-certificates
# sudo apt install gcc-aarch64-linux-gnu
# sudo apt install --no-install-suggests --no-install-recommends gcc-aarch64-linux-gnu
# git clone https://github.com/ipxe/ipxe ipxe-src
# ln -s ipxe-src/src/ src
# mkdir pxelinux.cfg
# mkdir -p ipxe/com1 ipxe/com2
# colormake compile > make-output.log

IPXEDIR=src
# org # MEMDISKDIR=/usr/share/syslinux/memdisk
MEMDISKDIR=/usr/lib/syslinux/memdisk
# org # PXELINUXDIR=/usr/share/syslinux/pxelinux.0
PXELINUXDIR=/usr/lib/PXELINUX/pxelinux.0
# org # CROSS_COMPILE=arm-linux-gnu-
CROSS_COMPILE=arm-none-eabi-
#CROSS_COMPILE=aarch64-linux-gnu-
#CROSS_COMPILE_64=aarch64-linux-gnu-

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
#CPUSJ=-j `$((`nproc`+0))`
#CPUSJ=-j`nproc --ignore=2`
CPUSJ=-j $(shell nproc --ignore=2)
#EATMYDATA=`$((command -v eatmydata))`
#EATMYDATA=`command -v eatmydata`
EATMYDATA=$(shell command -v eatmydata)
MEM=2560
#CPU=-smp 2 -cpu Skylake-Client-noTSX-IBRS
CPU=-smp 2 -cpu max
# org # QEMUKVM=qemu-kvm
#QEMUKVM=kvm
QEMUKVM=qemu-system-x86_64 -accel kvm
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
# org # DISK1=/dev/vg_work/qemu_test1,format=raw
# org # DISK2=/dev/vg_work/qemu_test2,format=raw
DISK1=/tmp/qemu_test1.qcow2
DISK2=/tmp/qemu_test2.qcow2
DISKS=$(DISK1) $(DISK2)
DISKTMP=/tmp/test1.img
DISKDRV="virtio"
# org # CACHE="none"
CACHE="unsafe"
#DISKS_FULL_PATH+=$(foreach disk,$(DISKS), $(IMGDIR)/$(disk))
override PARAMS+=$(foreach disk,$(DISKS),-drive file=$(disk),cache=$(CACHE),if=$(DISKDRV))
#override PARAMS+=-option-rom $(IPXEDIR)/bin/virtio-net.rom
# org # CA_TRUST=/usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit
CA_TRUST=/etc/ssl/certs/ca-certificates.crt

all:	rsync pciids.ipxe

.PHONY:	all clean sigs rsync compile syslinux

clean:
	+make -C sigs clean

sigs:
	+make -C sigs

rsync:	images/modules.cgz sigs
##	rsync -avPHC --inplace --delete ./ www.salstar.sk:public_html/boot/ \
##	  --exclude='**/.git*' --exclude='**/rsync' --exclude='src' \
##	  --exclude='.well-known'
##	# to tftp server for dhcp boot
##	rsync -avPH --inplace ipxe/*pxe ipxe/com* ipxe/*.efi \
##		ftp:/var/lib/tftpboot/ipxe/

# org # TRUST=$(shell find `pwd`/certs/ -name \*.crt -o -name \*.pem | xargs echo $(CA_TRUST) | tr ' ' ',')
TRUST=$(shell find `pwd`/certs/ -name \*.crt -o -name \*.pem | xargs echo $(CA_TRUST) | tr ' ' ',')
#TRUST=


ROOT_DIR := $(shell git rev-parse --show-toplevel)
#ipxe-src-directory = $(ROOT_DIR)/ipxe-src/src/ $(ROOT_DIR)/src/Makefile
#SRC_DIR ?= $(ROOT_DIR)/src/Makefile
#IPXE_SRC_DIR ?= $(ROOT_DIR)/ipxe-src/src/Makefile $(ROOT_DIR)/src/Makefile
IPXE_SRC_DIR ?= $(ROOT_DIR)/src
IPXE_CONFIG_LOCAL_DIR ?= $(IPXE_SRC_DIR)/config/local
IPXE_CONFIG_LOCAL ?= $(IPXE_CONFIG_LOCAL_DIR)/ $(IPXE_CONFIG_LOCAL_DIR)/com1 $(IPXE_CONFIG_LOCAL_DIR)/com2
#.PHONY: clone-ipxe
#clone-ipxe: | src/Makefile
# clone-ipxe: | $(ROOT_DIR)/src/

clone-ipxe: $(IPXE_SRC_DIR) $(IPXE_SRC_DIR)/Makefile
$(IPXE_SRC_DIR):
	git clone https://github.com/ipxe/ipxe ipxe-src
	ln -s ipxe-src/src/ src

#.PHONY: copy-config
copy-config: | $(IPXE_CONFIG_LOCAL_DIR) $(IPXE_CONFIG_LOCAL) clone-ipxe
$(IPXE_CONFIG_LOCAL_DIR):
	mkdir -p src/config/local/
#	cp -pvr ipxe/config/ src/config/local/
$(IPXE_CONFIG_LOCAL):
#	mkdir -p src/config/local/
	cp -pvr ipxe/config/* src/config/local/

compile:	syslinux	copy-config
	for config in $(IPXECONFIGS); do \
		$(EATMYDATA) make $(CPUSJ) -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
			TRUST=$(TRUST) $(TARGETS) $(IPXE_OPTS) \
			CONFIG=$$config $(ARGS) \
			NO_WERROR=1; \
		$(EATMYDATA) make $(CPUSJ) -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
			TRUST=$(TRUST) $(ARM_TARGETS) $(IPXE_OPTS) \
			CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm32 \
			#CROSS_COMPILE=$(CROSS_COMPILE) \
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
	rm -vfr ipxe/ipxe.iso* ipxe/*.efi ipxe/*.lkrn ipxe/*.kpxe ipxe/*.rom ipxe/*.usb ipxe/com1/* ipxe/com2/* $(IPXE_CONFIG_LOCAL_DIR)

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
$(DISKS):
	qemu-img create -f qcow2 -o preallocation=off $@ 8G
	#qemu-img create -f qcow2 -o preallocation=metadata $@ 8G

boot:	all
	#qemu-kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	#kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	$(QEMUKVM) -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
		-kernel ipxe/$(BOOTCONFIG)/ipxe.lkrn \
		-monitor $(MONITOR) -display $(OUT) \
		$(NET) \
		$(USB) \
		$(RNG) \
		$(PARAMS) \
		$(ARGS)
	@echo ""

boot.ipxe.org:
	mkdir -p ipxe/boot.ipxe.org/
	curl -LJR http://boot.ipxe.org/ipxe.lkrn -o ipxe/boot.ipxe.org/ipxe.lkrn

boot-boot.ipxe.org:	boot.ipxe.org
	#qemu-kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	#kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	$(QEMUKVM) -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
		-kernel ipxe/boot.ipxe.org/ipxe.lkrn \
		-monitor $(MONITOR) -display $(OUT) \
		$(NET) \
		$(USB) \
		$(RNG) \
		$(PARAMS) \
		$(ARGS)
	@echo ""

onlyboot:
	#qemu-kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	#kvm -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
	$(QEMUKVM) -m $(MEM) $(CPU) -boot once=$(BOOTORDER) \
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
	
stdioboot-boot.ipxe.org:
	# no-graphics, monitor on stdio
	@echo "Use CTRL+A + C + ENTER to QEMU monitor."
	+make boot-boot.ipxe.org OUT="none -nographic -serial mon:stdio" \
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
	#qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
	#qemu-system-x86_64 -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
	#kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
	$(QEMUKVM) -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE) -boot n \
		-display $(OUT) $(USB) $(RNG) $(PARAMS) $(ARGS)

efiboot:	all
	#qemu-kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE_EFI) \
	#kvm -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE_EFI) \
	$(QEMUKVM) -m $(MEM) $(NET),tftp=`pwd`,bootfile=$(BOOTFILE_EFI) \
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
#	cp -a $< $@
	cp -a --dereference $< $@

pxelinux.cfg/modules.pcimap:	/usr/lib/modules/$(UNAME)/modules.pcimap
	#cp -a $< $@
	cp -a --dereference $< $@

pxelinux.cfg/modules.alias:	/usr/lib/modules/$(UNAME)/modules.alias
	#cp -a $< $@
	cp -a --dereference $< $@

#pxelinux.cfg/pxelinux.0:	/usr/share/syslinux/pxelinux.0
pxelinux.cfg/pxelinux.0:	$(PXELINUXDIR)
	#cp -a $< $@
	cp -a --dereference $< $@

#pxelinux.cfg/%.c32:	/usr/share/syslinux/%.c32
#pxelinux.cfg/%.c32:	$(PXELINUX.CFG_C32_DIR)
pxelinux.cfg/%.c32:	$(PXELINUXDIR)
	cp -a $< $@

#memdisk:	/usr/share/syslinux/memdisk
memdisk:	$(MEMDISKDIR)
	cp -a $< $@

#images/memtest:	/boot/elf-memtest86+-$(MEMTEST_VERSION)
#	cp -a $< $@
#	touch $@

syslinux:	memdisk pxelinux.cfg/pci.ids pxelinux.cfg/modules.alias pxelinux.cfg/pxelinux.0 $(C32S:%=pxelinux.cfg/%.c32)
