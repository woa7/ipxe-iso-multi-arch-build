SIGN=openssl cms -sign -binary -noattr -signer ~/sal/codesign/codesign.crt -inkey ~/sal/codesign/codesign.key -certfile ~/sal/codesign/cacert.pem -outform DER

FTP=/home/ftp/pub

IPXE=$(shell cd ..; find . -name '*.ipxe' -and ! -path '*/examples/*')
IPXEBIN=ipxe/ipxe.lkrn ipxe/com1/ipxe.lkrn ipxe/com2/ipxe.lkrn
FEDORA=$(shell cd $(FTP); ls -1 \
	  fedora/linux/releases/*/*/*/os/isolinux/vmlinuz \
	  fedora/linux/releases/*/*/*/os/isolinux/initrd.img \
	  fedora/linux/releases/*/*/*/os/images/pxeboot/vmlinuz \
	  fedora/linux/releases/*/*/*/os/images/pxeboot/initrd.img \
	  fedora/linux/releases/test/*/*/*/os/isolinux/vmlinuz \
	  fedora/linux/releases/test/*/*/*/os/isolinux/initrd.img \
	)
CENTOS=$(shell cd $(FTP); ls -1 \
	  centos/*/os/*/isolinux/vmlinuz \
          centos/*/os/*/isolinux/initrd.img \
	  centos/*/os/*/images/pxeboot/vmlinuz \
          centos/*/os/*/images/pxeboot/initrd.img \
          centos*/*/BaseOS/*/os/isolinux/vmlinuz \
          centos*/*/BaseOS/*/os/isolinux/initrd.img \
          centos*/*/BaseOS/*/os/images/pxeboot/vmlinuz \
          centos*/*/BaseOS/*/os/images/pxeboot/initrd.img \
	)
CENTOS_VAULT=\
	centos-vault/8/BaseOS/x86_64/os/isolinux/vmlinuz \
	centos-vault/8/BaseOS/x86_64/os/isolinux/initrd.img \
	centos-vault/8/BaseOS/x86_64/os/images/pxeboot/vmlinuz \
	centos-vault/8/BaseOS/x86_64/os/images/pxeboot/initrd.img
CENTOS_i386=\
	centos/7/os/i386/isolinux/vmlinuz \
	centos/7/os/i386/isolinux/initrd.img
ALMALINUX=$(shell cd $(FTP)/mirrors; ls -1 \
	almalinux/*/BaseOS/x86_64/os/isolinux/vmlinuz \
	almalinux/*/BaseOS/x86_64/os/isolinux/initrd.img \
	almalinux/*/BaseOS/x86_64/os/images/pxeboot/vmlinuz \
	almalinux/*/BaseOS/x86_64/os/images/pxeboot/initrd.img \
	)
ROCKYLINUX=\
	rocky/9/BaseOS/x86_64/os/isolinux/vmlinuz \
	rocky/9/BaseOS/x86_64/os/isolinux/initrd.img \
	rocky/9/BaseOS/x86_64/os/images/pxeboot/vmlinuz \
	rocky/9/BaseOS/x86_64/os/images/pxeboot/initrd.img \
	rocky/8/BaseOS/x86_64/os/isolinux/vmlinuz \
	rocky/8/BaseOS/x86_64/os/isolinux/initrd.img \
	rocky/8/BaseOS/x86_64/os/images/pxeboot/vmlinuz \
	rocky/8/BaseOS/x86_64/os/images/pxeboot/initrd.img
SCIENTIFIC=\
	scientific/7x/x86_64/os/isolinux/vmlinuz \
	scientific/7x/x86_64/os/isolinux/initrd.img \
	scientific/6x/x86_64/os/isolinux/vmlinuz \
	scientific/6x/x86_64/os/isolinux/initrd.img \
	scientific/6x/i386/os/isolinux/vmlinuz \
	scientific/6x/i386/os/isolinux/initrd.img
PMAGIC=$(shell cd $(FTP); find mirrors/pmagic -name bzImage\* -or -name initrd.img)
CLONEZILLA=$(shell cd $(FTP); find mirrors/clonezilla -name vmlinuz -or -name initrd.img)
FREEDOS=$(shell cd $(FTP); find mirrors/images -type f)

SOURCES=\
	$(IPXE) $(IPXEBIN) \
	memdisk \
	pxelinux.0 pxelinux.cfg/pxelinux.0 pxelinux.cfg/lpxelinux.0 \
	$(shell cd ..; echo images/*.* images/pcmemtest/* \
		images/mt86plus/*.* images/mt86plus/*/*/*) \
	$(FEDORA) \
	$(CENTOS) $(CENTOS_VAULT) $(CENTOS_i386) \
	$(ALMALINUX) \
	$(ROCKYLINUX) \
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

ipxe/%.sig:	../ipxe/%
	$(SIGN) -in $< -out $@

bsd/%.ipxe.sig:	../bsd/%.ipxe
	mkdir -p bsd
	$(SIGN) -in $< -out $@

images/%.sig:	../images/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

fedora/%.sig:	$(FTP)/fedora/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

centos/%.sig:	$(FTP)/centos/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

NOSIG=$(@:.sig=)
centos/7/os/i386/isolinux/%.sig:
	@mkdir -p `dirname $@`
	curl http://mirror.centos.org/altarch`echo $(NOSIG) | sed 's/^centos//'` \
	  | $(SIGN) -in - -out $@

centos-stream/%.sig:	$(FTP)/centos-stream/%
	# centos-stream is a link to centos, create centos directory first
	@mkdir -p centos `dirname $@`
	$(SIGN) -in $< -out $@
	#curl http://mirror.stream.centos.org`echo $(NOSIG) | sed 's/^centos-stream//'` \
	#  | $(SIGN) -in - -out $@

centos-vault/%.sig:	$(FTP)/mirrors/centos-vault/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

almalinux/%.sig:	$(FTP)/mirrors/almalinux/%
	@mkdir -p `dirname $@`
	#curl https://repo.almalinux.org/$(NOSIG) | $(SIGN) -in - -out $@
	$(SIGN) -in $< -out $@

rocky/%.sig:
	@mkdir -p `dirname $@`
	curl https://download.rockylinux.org/pub/$(NOSIG) \
	  | $(SIGN) -in - -out $@

scientific/%.sig:
	@mkdir -p `dirname $@`
	curl http://ftp.scientificlinux.org/linux/$(NOSIG) \
	  | $(SIGN) -in - -out $@

mirrors/%.sig:	$(FTP)/mirrors/%
	@mkdir -p `dirname $@`
	$(SIGN) -in $< -out $@

memdisk.sig:	../memdisk
	$(SIGN) -in $< -out $@

pxelinux.0.sig:	../pxelinux.0
	$(SIGN) -in $< -out $@

pxelinux.cfg/pxelinux.0.sig:	../pxelinux.cfg/pxelinux.0
	$(SIGN) -in $< -out $@

pxelinux.cfg/lpxelinux.0.sig:	../pxelinux.cfg/lpxelinux.0
	$(SIGN) -in $< -out $@

memtest.0.sig:	../images/memtest.0
	$(SIGN) -in $< -out $@

memtest5.lkrn.sig:	../images/memtest5.lkrn
	$(SIGN) -in $< -out $@

pciids/%.ipxe.sig:	../pciids/%.ipxe
	mkdir -p pciids
	$(SIGN) -in $< -out $@
