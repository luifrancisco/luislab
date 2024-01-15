#!/bin/bash
# download the image


# create a new VM with VirtIO SCSI controller
qm create 9002 --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci --name "ubuntu-22-04-template"

# import the downloaded disk to the nvme-b storage, attaching it as a SCSI drive
qm set 9002 --scsi0 nvme-b:0,import-from=/root/images/jammy-server-cloudimg-amd64.img


# **Ubuntu Cloud-Init images require the virtio-scsi-pci controller type for SCSI drives.**

# attach cd-rom(ide drive) for passing data to cloud-init image
qm set 9002 --ide2 nvme-b:cloudinit

# skip cd-rom checks and restrict VM to boot only from scsi drive.
qm set 9002 --boot order=scsi0


# configure serial console to output display
qm set 9002 --serial0 socket --vga serial0

# import public ssh key
#qm set 9004 --sshkeys /root/sshkeys/luis-dakanyama_id_rsa.pub

# enable qemu-agent
qm set 9002 --agent enabled=1

# convert VM to template
qm template 9002
