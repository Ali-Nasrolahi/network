DISK_DIR	= 	disk/
ISO_DIR 	= 	iso/

DEB_DISK	=	$(DISK_DIR)/debian.qcow2
PF_DISK		=	$(DISK_DIR)/pfsense.qcow2
KALI_DISK	=	$(DISK_DIR)/kali.qcow2

DEB_ISO		=	$(ISO_DIR)/debian.iso
PF_ISO		=	$(ISO_DIR)/pfSense-CE-2.7.0-RELEASE-amd64.iso
TINY_ISO	= 	$(ISO_DIR)/tiny-core.iso
KALI_ISO	= 	$(ISO_DIR)/kali-linux-2024.1-installer-amd64.iso

QEMU_OPT	= 	-enable-kvm -smp 2 -m 1024 -vga qxl


all: tuntap ovs enable_tap kali debian pfsense

debian:
	sudo qemu-system-x86_64 $(QEMU_OPT) -hda $(DEB_DISK) \
		-device e1000,mac=50:54:00:00:00:40,netdev=lan,id=lan \
		-netdev tap,id=lan,ifname=debian_lan_tap,script=no,downscript=no &

pfsense:
	sudo qemu-system-x86_64 $(QEMU_OPT) -hda $(PF_DISK) \
		-device e1000,mac=50:54:00:00:00:42,netdev=wan,id=wan \
		-netdev tap,id=wan,ifname=pfsense_wan_tap,script=no,downscript=no \
		-device e1000,mac=50:54:00:00:00:43,netdev=lan,id=lan \
		-netdev tap,id=lan,ifname=pfsense_lan_tap,script=no,downscript=no &
#-netdev user,id=lan,net=192.168.1.0/24,dhcpstart=192.168.1.8,hostfwd=::443-192.168.1.8:443 &

tiny:
	sudo qemu-system-x86_64 $(QEMU_OPT) -cdrom  $(TINY_ISO) \
		-device e1000,mac=50:54:00:00:00:41,netdev=lan,id=lan \
		-netdev tap,id=lan,ifname=tiny_lan_tap,script=no,downscript=no &

kali:
	sudo qemu-system-x86_64 $(QEMU_OPT) -hda $(KALI_DISK) \
		-device e1000,mac=50:54:00:00:00:44,netdev=wan,id=wan \
		-netdev tap,id=wan,ifname=kali_wan_tap,script=no,downscript=no &

ovs:
	sudo ovs-vsctl add-br wan_sw
	sudo ovs-vsctl add-br lan_sw
	sudo ovs-vsctl add-port wan_sw kali_wan_tap
	sudo ovs-vsctl add-port wan_sw pfsense_wan_tap
	sudo ovs-vsctl add-port lan_sw pfsense_lan_tap
	sudo ovs-vsctl add-port lan_sw debian_lan_tap
	sudo ovs-vsctl add-port lan_sw tiny_lan_tap
	sudo ip l set lan_sw up
	sudo ip a add 192.168.1.100/24 dev lan_sw
	sudo ovs-vsctl show

tuntap:
	sudo ip tuntap add mode tap kali_wan_tap
	sudo ip tuntap add mode tap pfsense_wan_tap
	sudo ip tuntap add mode tap pfsense_lan_tap
	sudo ip tuntap add mode tap debian_lan_tap
	sudo ip tuntap add mode tap tiny_lan_tap

enable_tap:
	sudo ip l set up kali_wan_tap
	sudo ip l set up pfsense_wan_tap
	sudo ip l set up pfsense_lan_tap
	sudo ip l set up debian_lan_tap
	sudo ip l set up tiny_lan_tap
	ip -br a

clean: clean_tuntap clean_ovs

clean_ovs:
	sudo ovs-vsctl del-br wan_sw
	sudo ovs-vsctl del-br lan_sw
	sudo ovs-vsctl show
	ip -br a

clean_tuntap: disable_tap
	sudo ip tuntap del mode tap tiny_lan_tap
	sudo ip tuntap del mode tap debian_lan_tap
	sudo ip tuntap del mode tap pfsense_lan_tap
	sudo ip tuntap del mode tap pfsense_wan_tap
	sudo ip tuntap del mode tap kali_wan_tap
	ip -br a

disable_tap:
	sudo ip l set down tiny_lan_tap
	sudo ip l set down debian_lan_tap
	sudo ip l set down pfsense_lan_tap
	sudo ip l set down pfsense_wan_tap
	sudo ip l set down kali_wan_tap


.PHONY: all debian pfsense tuntap clean
