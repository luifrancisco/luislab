terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.43.0"
    }
  }
}

provider "proxmox" {
  # Configuration options
  endpoint = "https://10.0.0.14:8006/api2/json/"
  api_token = var.pm_api_token_idsecret
  insecure = true
}

provider "proxmox" {
   # Configuration options
  alias = "pve4"
  endpoint = "https://10.0.0.14:8006/api2/json/"
  api_token = var.pm_api_token_idsecret
  insecure = true
}

variable "ciuser" {
    type = string
}

variable "cipassword" {
    type = string
}

variable "pm_api_token_id" {
    type = string
}
variable "pm_api_token_secret" {
    type = string
}

variable "pm_api_token_idsecret" {
    type = string
}

variable "env_ssh_key" {
    type = list
}

resource "proxmox_virtual_environment_vm" "stg-k8s-master-1" {
  provider = proxmox.pve4
  name = "stg-k8s-master-1"
  node_name = "pve4"
  vm_id = 4101
  tablet_device = false
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
  }

  clone {
    vm_id = 9001
    full = true
  }

  cpu {
    cores = 4
    type = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "nvme-a"
    interface = "scsi0"
    size = 20
    iothread = true
    ssd = true
  }

  network_device {
    model = "virtio"
    bridge = "vmbr0"
    firewall = false
    vlan_id = 20
  }

  initialization {
    datastore_id = "nvme-a"
    user_account {
      username = var.ciuser
      password = var.cipassword
      keys = var.env_ssh_key
    }
    ip_config {
      ipv4 {
        address = "10.20.0.91/24"
        gateway = "10.20.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "stg-k8s-master-2" {
  provider = proxmox.pve4
  name = "stg-k8s-master-2"
  node_name = "pve4"
  vm_id = 4102
  tablet_device = false
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
  }

  clone {
    vm_id = 9002
    full = true
  }

  cpu {
    cores = 4
    type = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "nvme-b"
    interface = "scsi0"
    size = 20
    iothread = true
    ssd = true
  }

  network_device {
    model = "virtio"
    bridge = "vmbr0"
    firewall = false
    vlan_id = 20
  }

  initialization {
    datastore_id = "nvme-b"
    user_account {
      username = var.ciuser
      password = var.cipassword
      keys = var.env_ssh_key
    }
    ip_config {
      ipv4 {
        address = "10.20.0.92/24"
        gateway = "10.20.0.1"
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "stg-k8s-master-3" {
  provider = proxmox.pve4
  name = "stg-k8s-master-3"
  node_name = "pve4"
  vm_id = 4103
  tablet_device = false
  scsi_hardware = "virtio-scsi-single"
  agent {
    enabled = true
  }

  clone {
    vm_id = 9003
    full = true
  }

  cpu {
    cores = 4
    type = "host"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "nvme-c"
    interface = "scsi0"
    size = 20
    iothread = true
    ssd = true
  }

  network_device {
    model = "virtio"
    bridge = "vmbr0"
    firewall = false
    vlan_id = 20
  }

  initialization {
    datastore_id = "nvme-c"
    user_account {
      username = var.ciuser
      password = var.cipassword
      keys = var.env_ssh_key
    }
    ip_config {
      ipv4 {
        address = "10.20.0.93/24"
        gateway = "10.20.0.1"
      }
    }
  }
}


