SIGN=openssl cms -sign -binary -noattr -signer ~/sal/codesign/codesign.crt -inkey ~/sal/codesign/codesign.key -certfile ~/sal/codesign/ca.crt -outform DER

FTP=/home/ftp/pub

IPXE=$(shell cd ..; echo *.ipxe)
FEDORA=$(shell cd $(FTP); \
	echo fedora/linux/*/*/Fedora/*/os/isolinux/vmlinuz \
	     fedora/linux/*/*/Fedora/*/os/isolinux/initrd.img \
	     fedora/linux/*/*/*/Fedora/*/os/isolinux/vmlinuz \
	     fedora/linux/*/*/*/Fedora/*/os/isolinux/initrd.img \
	)
CENTOS=$(shell cd $(FTP); \
	echo centos/*/os/*/isolinux/vmlinuz \
             centos/*/os/*/isolinux/initrd.img \
	)
PMAGIC=$(shell cd $(FTP); find mirrors/pmagic -name bzImage -or -name initrd.img)
FREEDOS=$(shell cd $(FTP); find mirrors/freedos -type f)

SOURCES=\
	$(IPXE) \
	memdisk \
	pxelinux.0 \
	$(shell cd ..; echo images/*) \
	$(FEDORA) \
	$(CENTOS) \
	$(PMAGIC) \
	$(FREEDOS) \

TARGETS=$(SOURCES:=.sig)

all:	$(TARGETS)

clean:
	rm -f $(TARGETS)
	rm -rf images fedora centos mirrors

echo:
	for i in $(SOURCES); do echo $$i; done

%.ipxe.sig:	../%.ipxe
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

mirrors/%.sig:	$(FTP)/mirrors/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

memdisk.sig:	../memdisk
	$(SIGN) -in $< -out $@

pxelinux.0.sig:	../pxelinux.0
	$(SIGN) -in $< -out $@
