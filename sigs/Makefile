SIGN=openssl cms -sign -binary -noattr -signer ~/sal/codesign/codesign.crt -inkey ~/sal/codesign/codesign.key -certfile ~/sal/codesign/cacert.pem -outform DER

FTP=/home/ftp/pub

IPXE=$(shell cd ..; find . -name '*.ipxe')
FEDORA=$(shell cd $(FTP); ls -1 \
	  fedora/linux/releases/*/Fedora/*/os/isolinux/vmlinuz \
	  fedora/linux/releases/*/Fedora/*/os/isolinux/initrd.img \
	  fedora/linux/releases/test/*/Fedora/*/os/isolinux/vmlinuz \
	  fedora/linux/releases/test/*/Fedora/*/os/isolinux/initrd.img \
	)
CENTOS=$(shell cd $(FTP); ls -1 \
	  centos/*/os/*/isolinux/vmlinuz \
          centos/*/os/*/isolinux/initrd.img \
	)
SCIENTIFIC=\
	scientific/6x/x86_64/os/isolinux/vmlinuz \
	scientific/6x/x86_64/os/isolinux/initrd.img \
	scientific/6x/i386/os/isolinux/vmlinuz \
	scientific/6x/i386/os/isolinux/initrd.img \
	scientific/5x/x86_64/isolinux/vmlinuz \
	scientific/5x/x86_64/isolinux/initrd.img \
	scientific/5x/i386/isolinux/vmlinuz \
	scientific/5x/i386/isolinux/initrd.img
PMAGIC=$(shell cd $(FTP); find mirrors/pmagic -name bzImage\* -or -name initrd.img)
CLONEZILLA=$(shell cd $(FTP); find mirrors/clonezilla -name vmlinuz -or -name initrd.img)
FREEDOS=$(shell cd $(FTP); find mirrors/images -type f)

SOURCES=\
	$(IPXE) \
	memdisk \
	pxelinux.0 \
	memtest.0 \
	$(shell cd ..; echo images/*) \
	$(FEDORA) \
	$(CENTOS) \
	$(SCIENTIFIC) \
	$(PMAGIC) \
	$(CLONEZILLA) \
	$(FREEDOS) \

TARGETS=$(SOURCES:=.sig)

all:	$(TARGETS)

clean:
	rm -f $(TARGETS)
	rm -rf images fedora centos mirrors bsd scientific

echo:
	for i in $(SOURCES); do echo $$i; done

%.ipxe.sig:	../%.ipxe
	$(SIGN) -in $< -out $@

bsd/%.ipxe.sig:	../bsd/%.ipxe
	mkdir -p bsd
	$(SIGN) -in $< -out $@

images/%.sig:	../images/%
	@mkdir -p images
	$(SIGN) -in $< -out $@

fedora/%.sig:	$(FTP)/fedora/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

centos/%.sig:	$(FTP)/centos/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

NOSIG=$(@:.sig=)
scientific/%.sig:
	@mkdir -p `dirname $@`
	wget -O $(NOSIG) http://ftp.scientificlinux.org/linux/$(NOSIG)
	$(SIGN) -in $(NOSIG) -out $@
	rm -f $(NOSIG)

mirrors/%.sig:	$(FTP)/mirrors/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

memdisk.sig:	../memdisk
	$(SIGN) -in $< -out $@

pxelinux.0.sig:	../pxelinux.0
	$(SIGN) -in $< -out $@

memtest.0.sig:	../images/memtest.0
	$(SIGN) -in $< -out $@
