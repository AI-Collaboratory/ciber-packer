Building CI-BER VMs
===================

The packer command will create a machine and auto-install Ubuntu 16.04 Server with these features:

* Ubuntu Server packages, Open SSH server
* Custom user, configured for sudo w/o password prompts
* Auto-install of security updates
* Scripted purging of old kernels from /boot after reboot
* Ready for Ansible plays (python-simplejson package installed)

The resulting image will be placed in /export/vm/<my host>/<my host>.raw
It will be imported into Qemu/Libvirt via the virt-install command with all three CI-BER networks:

* ens3 - external network (NAT) (default gateway)
* ens4 - EXT network (192.168.0.x)
* ens5 - REP network (192.168.1.x)


== Steps

* Install packer command from http://packer.io.

* Clone this repository to your virtual host.

* Run the packer command with your variables as arguments:

    packer build -var 'hostname=<my host>' -var 'user=<my user>' -var 'password=<my password>' -var 'ncpus=<cpu count>' -var 'memory=2048' -var 'domain=ext' ubuntu-16.04-server-amd64.json

To debug, insert the environment variable PACKER_LOG=1 in front of your packer command.
