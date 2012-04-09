IPXEDIR=../../../c/ipxe/src
TARGETS=bin/ipxe.lkrn bin/ipxe.pxe bin/ipxe.iso
MEM=768
NETMODEL=virtio
NET=-net nic,model=$(NETMODEL) -net user

all:	compile copy

compile:
	make -j1 -C $(IPXEDIR) EMBEDDED_IMAGE=`pwd`/link.ipxe \
		TRUST=`pwd`/upjs.pem,`pwd`/terena.pem \
		$(TARGETS)

copy:
	for i in $(TARGETS); do \
		cp -a $(IPXEDIR)/$$i .; \
	done

test:	all
	../rsync
	qemu-kvm -m $(MEM) -kernel $(IPXEDIR)/bin/ipxe.lkrn $(NET) $(ARGS)

freedos:
	zip /tmp/fd11live.img.zip fd11live.img
	rsync -avP ./fd11live.img /tmp/fd11live.img.zip \
		mirror@ftp:/home/ftp/pub/mirrors/freedos/1.1/
	gzip -c1 fd11live.img | ssh mirror@ftp \
		dd of=/home/ftp/pub/mirrors/freedos/1.1/fd11live.img.gz
