# IDS / IPS Scenario Lab

This scenario is based on using pfSense and Snort as IDS/IPS module. For setting up this lab you need a couple of things:

- Linux with IP(8) enabled. We use it to create TAP port for our Virtual Machines
- QEMU x86-64 as our emulator
- Openvswitch is used for switching between our pfSense and our client/server
- pfSense, Debian, Kali linux iso (Place them in iso/ directory)
- At least 15G of disk space for pfSense, Debian and Kali linux
- (optional) TinyCore iso for lightweight testing

There's no necessity to use distros that I've chosen, any minimal Linux will do just fine!
Just make sure you have your tools ready to use. like: IP(8), tcpdump(1) and so on.

