Building CI-BER VMs
===================

The packer command will create a machine and auto-install Ubuntu 16.04 Server with these features:

* Ubuntu Server packages, Open SSH server
* Custom user, configured for sudo w/o password prompts
* Auto-install of security updates
* Scripted purging of old kernels from /boot after reboot
* Ready for Ansible plays (python-simplejson package installed)

The resulting image will be placed in /export/vm/<my host>/<my host>.raw
It will be imported into Qemu/Libvirt via the virt-install command with all three CI-BER networks on these devices:

* ens3 - external network (NAT) (default gateway)
* ens4 - EXT network (192.168.0.x)
* ens5 - REP network (192.168.1.x)

# Steps

1. Install packer command from http://packer.io.

1. Clone this repository to your image building machine with KVM installed. I use my laptop to run packer, then copy images to the virtual host. Finding that images are more portable than my Qemu build template.

1. Run the packer command with your variables as arguments:
```shell
$ packer build \
    -var 'hostname=<my host>' \
    -var 'user=<my user>' \
    -var 'password=<my password>' \
    -var 'ncpus=<cpu count>' \
    -var 'memory=2048' \
    -var 'disk_size=32000' \
    -var 'domain=ext' \
    ubuntu-16.04-server-amd64.json
```
  * There are defaults for many of the variables, see the JSON template file.
  * To debug, insert the environment variable PACKER_LOG=1 in front of your packer command.

1. Copy the compressed image file to the images location on to your virtual host:
```shell
$ scp <my host>.raw.gz <virtual host 1>:~ <virtual host 2>:~ <virtual host 3>:~
```

1. Unzip the image file and place it in your Qemu images location, giving it correct ownership permissions. Your steps may vary:
```shell
$ sudo gunzip -c ~/<my host>.raw.gz >/export/vm/<my host>.raw
$ sudo chown qemu /export/vm/<my host>.raw
$ sudo chgrp qemu /export/vm/<my host>.raw
$ sudo chmod 600 /export/vm/<my host>.raw
```

1. Install the machine in the Qemu Hypervisor:
```shell
virt-install --import \
 --graphics vnc \
 --noautoconsole \
 --connect=qemu+tcp://<user>@<virtual host>/system \
 --os-type=linux \
 --os-variant=ubuntuquantal \
 -n <my host> \
 -r 32768 \
 --vcpus=8 \
 --disk path=/export/vm/<my host>.raw,device=disk,bus=virtio,format=raw,cache=writeback \
 --network network=default \
 --network bridge=ext0 \
 --network bridge=rep0
```

1. You can connect to your guest via SSH or through the serial console. It does not have a graphical console. In the virt-viewer GUI, select Serial 1, under Text Consoles. Or connect with virsh:
```shell
$ virsh --connect=qemu+tcp://<user>@<virtual host>/system console <vm name>
```

# Using the Image as a Base for Cloning
If you are using this image as a template for all new guest machines, then you need to shut it down, then create a cloned machine from the template machine. Give it the name you want and rename the disk image to match.

1. I find it quicker to use the virt-clone command than the GUI:
```shell
virt-clone --connect=qemu+tcp://<user>@<virtual host>/system -o <my host> -n <new guest hostname> -f /export/vm/<new guest hostname>.raw
```

1. Start your clone in virt-manager. It is now running as the correct name in KVM, but the hostname is set to <my host> and this appears in the DHCP DNS.

1. Run the set_hostname.yml playbook to configure the hostname of your new guest. Your SSH configuration must be capable of reaching the clone at it's <my host> address. Add more SSH options as appropriate:
```shell
ansible-playbook -i <my host>, -e hostname=<new guest hostname>
```

1. Repeat as needed! WARNING: Do not start multiple clones at the same time. They will all have the same hostname until you follow these steps, and DNS will break.

# Using Ansible to Change Passwords on Many Hosts
The password you used in your template is powerful and as your template gets older, you may want to change it as it proliferates on many templated systems.

1. Generate new password hash:
```shell
$ python3 -c 'import crypt; print(crypt.crypt("<your new password>", crypt.mksalt(crypt.METHOD_SHA512)))'
```

1. Use the Ansible User module to update passwords on selected hosts:
```shell
$ ansible all -m user -k -a "name=<my user> password=<new hashed password>"
```
