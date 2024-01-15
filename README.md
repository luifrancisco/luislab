# K3S-HA

Welcome to my first major homelab project. This repository contains all the Terraform and Ansible scripts that will help you spin up your own kubernetes cluster with HA in place.

Terraform will be used to instantiate the VMs on Proxmox and Ansible to configure the cluster from scratch.

*Read the [Ansible documentation](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#pipx-install) for the installation procedure*
*Read the [Terraform documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) for the installation procedure*

The terraform script by default will 3 VMs with two disks attached.

## Pre-requisites
- Management VM or container with Ansible and Terraform installed
- Kubernetes module for Ansible (install with `ansible-galaxy collection install community.kubernetes`)
- Proxmox Virtual Environment (tested with the latest PVE v8.3.1 as of 2024.01.07)
- Proxmox user with correct permissions to be used with Terraform (Follow [here](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs#creating-the-proxmox-user-and-role-for-terraform))

## How to use:
### Prepare Proxmox
1. Download the repository
`git clone https://github.com/luifrancisco/luislab`

2. Copy the files in k3s-ha/scripts directory to your Proxmox host.
e.g.
```
cd k3s-ha/pve/scripts
scp scripts/create-ubuntu-2204-cloud-init_pve0 pve4:~/scripts
```

3. Login to the proxmox host and change the ownership of the file in the scripts directory.
```
chmod u+x create-ubuntu-2204-cloud-init-pve4-local-lvm.sh
```

4. Execute `create-ubuntu-2204-cloud-init-pve4-local-lvm.sh` shell script on main proxmox host. Notice the new image template created in Proxmox GUI.
`sh ~/scripts/create-ubuntu-2204-cloud-init-pve4-local-lvm.sh`

### Prepare Terraform
5. Go to k3s-ha/terraform/terraform.tfvars and modify the token.

Following environment variables need to be set:
```
export TF_VAR_env_ssh_key='["your_ssh_key_here"]'
export TF_VAR_ciuser = "your_cloudinit_user_here"
export TF_VAR_cipassword = "your_cloudinit_pw_here"
export TF_VAR_pm_api_token_id = "terraform-prov@pve!terraform-prov-token"
export TF_VAR_pm_api_token_secret = "2c9f7a40-1111-1111-1111-lfb25cf66583"
export TF_VAR_pm_api_token_idsecret = "your_api_token_id_here=your_api_secret_here"
# e.g.
# export TF_VAR_pm_api_token_idsecret = "terraform-prov@pve!terraform-prov-token=2c9f7a40-1111-1111-1111-lfb25cf66583"
```

6. Modify main.tf and change the following:
`provider`

`resource` *and the following under each resource*:
`resource.name`
`resource.node_name`
`resource.vm_id`
`resource.cpu.core` *- set to `4`` but should also work with `2`*
`resource.cpu.type` *- set to `host` to enable AVX support required for mongodb*
`resource.memory` *- set to 4GB but should also work with 2GB (haven't tested)*
`resource.disk.datastore_id` *- nvme-a is specific to my environment. Normally this will be `local-lvm` if you are using single disk.*
`resource.disk.size` *- set to 20GB for minimal deployment.*
`resource.network_device.vlan_id` *- optional. Remove if you will not be using vlans*
`resource.initialization.datastore_id`
`resource.initialization.ip_config.ipv4.address`
`resource.initialization.ip_config.ipv4.gateway`

**Note: resource.disk.iothread and resource.disk.ssd even when set to 1 are not applied to the VM due to a bug. Although recommended if you are using ssd, it's optional to change this manually.**

Basically anything according to your liking.

7. From here on we will be creating a Terraform user.
Query the pve roles with `pveum role list`

8. Create a role to be used with Terraform:
`pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt SDN.Use"`

9.  Create terraform user.
Go to Datacenter > Permissions > Roles. Fill in the username and password. Set the realm to `Proxmox VE authentication server`.
As an alternative step you can also execute: `pveum user add terraform-prov@pve --password <password>`

10. Map role to user. Go to Datacenter > Permissions.

11. Create API token in Data center > Permissions > API token. Create a token for the user created in the previous step. Fill in the Token ID with any name (e.g. terraform-prov-token). Ensure `Privilege Seperation` is **unchecked** set to **No**.

12. Update `k3s-ha/terraform/terraform.tfvars` with your ansible user password, public ssh key, and terraform token created in the previous step.

### Prepare Ansible

13. Modify ansible inventory in ~/k3s-ha/ansible/playbooks
```
all:
  hosts:
  children:
    main:
      hosts:
        10.20.0.91:
    members:
      hosts:
        10.20.0.92:
        10.20.0.93:
  vars:
    ansible_user: ansible
    _vip: 10.20.0.90
    _interface: eth0
    _clustercidr: 10.42.0.0/16
    _podcidr: 10.42.0.0/16
    _longhornversion: 1.5.1
    _ciliumVersion: 1.14.5
    _k8sInitialServiceHost: 10.20.0.91
    _k8sInitialMasterHostname: stg-k8s-master-1
```

14. Modify preflight yaml /etc/hosts configuration to reflect expected hostname and IP address.
15. Upload your public ssh key to k3s-ha/ansible/playbooks/authorized_keys/mypublicsshkey.pub

### Execution

15. Go to `k3s-ha/terraform` and execute `terraform apply`
16. Go to `k3s-ha/ansible/playbooks` and execute the `ansible-playbook -i inventory.yaml preflight.yaml`. Note that this will take time since it will upgrade the kernel version to 6.x which is required to have sctp working properly with Cilium.

17. After reboot execute `ansible-playbooks -i inventory k3s-kubevip-helm-ciliumInstallHelmCli.yaml`. As the name suggests this will install k3s, kube-vip, helm, and cilium on all nodes.

18. Execute `ansible-playbooks -i inventory longhorn-install-default-path.yaml` to install longhorn and use the default path of `/var/lib/longhorn`.

Installation of k3s-ha ends here. At this point you should have a fully working highly available k3s cluster with embedded etcd with Cilium as the CNI and Longhorn as your persistent storage backend.

### Misc

- To access the Longhorn UI with port-forwarding, execute: `kubectl -n longhorn-system port-forward deployment/longhorn-ui 8000:8000`. Access with `http://localhost:8000` in your browser.

### Future plans
- Remove kube-vip and use HA proxy instead.