# Vagrant with VMware Workstation Pro on Linux

This guide documents how I set up **Vagrant with VMware Workstation Pro on Linux** for **Rocky Linux 9** and **Rocky Linux 10** lab machines.

The goal was to create a repeatable RHCSA-style lab environment using Vagrant, VMware Workstation Pro, and Rocky Linux boxes, with an additional small lab disk attached to the server VM.

## Tested with

- Host OS: Linux Mint
- VMware Workstation Pro: 25H2u1
- Vagrant provider: `vmware_desktop`
- Vagrant VMware plugin: `vagrant-vmware-desktop`
- Vagrant VMware Utility: `1.0.24`
- Guest boxes:
  - `bento/rockylinux-9`
  - `bento/rockylinux-10`

> The exact Broadcom release names may change over time. This guide describes the version and naming that worked for me at the time of writing.

## Prerequisites

This guide assumes that you have:

- a Linux host
- Vagrant installed
- a Broadcom account for downloading VMware Workstation Pro
- basic familiarity with Vagrant commands
- enough disk space for the Vagrant boxes and VMware virtual machines

## 1. Download VMware Workstation Pro from Broadcom

VMware Workstation Pro for Linux is downloaded from the **Broadcom Support Portal**.

Broadcom states that the free version does not require a license key, and that the free offering is available for **Workstation Pro 17.5.2 and above**.

At the time of writing, the Broadcom portal used the newer **25H2** style naming.

The product branch I used was:

```text
VMware Workstation Pro 25H2 for Linux
```

Under **Release**, I selected:

```text
25H2u1
```

I did **not** use the older branch:

```text
VMware Workstation Pro 17.0 for Linux
```

Broadcom notes that users without older entitlement can get a **Not Entitled** error when trying to download versions lower than **17.5.2**, so the old 17.0 branch was not the right one for this setup.

## 2. Broadcom download checkbox workaround

The Broadcom download page can be confusing.

Download page:

```text
https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true
```

On the download page, I had to do the following:

1. Click the **Terms and Conditions** hyperlink first.
2. Read/open the agreement page.
3. Go back to the product download page.
4. Only then did the checkbox become usable.

Broadcom documents this behavior: clicking the Terms and Conditions link and returning to the product page enables the checkbox.

If the download still does not activate, Broadcom suggests refreshing the page or switching browsers.

If a popup appears saying **additional verification is required**, click **Yes**, fill out the form, and then the download icon should become available.

## 3. Install VMware Workstation Pro

After downloading the Linux `.bundle` installer, make it executable and run it locally.

On my Linux Mint machine, I used:

```bash
chmod +x ~/Downloads/VMware-Workstation-Full-*.bundle
sudo ~/Downloads/VMware-Workstation-Full-*.bundle
vmware
```

After installation, start VMware Workstation once to complete any first-run setup.

## 4. Install the Vagrant VMware components

For Vagrant to work with VMware Workstation, installing Vagrant alone is not enough.

You need:

- Vagrant
- the `vagrant-vmware-desktop` plugin
- the separate Vagrant VMware Utility system package

### Install the Vagrant plugin

```bash
vagrant plugin install vagrant-vmware-desktop
```

### Install the Vagrant VMware Utility

Download the utility package from HashiCorp, then install it.

For the `.deb` package I used:

```bash
cd ~/Downloads
sudo apt install ./vagrant-vmware-utility_1.0.24-1_amd64.deb
sudo systemctl enable --now vagrant-vmware-utility
sudo systemctl status vagrant-vmware-utility
```

On Linux, the service is called:

```text
vagrant-vmware-utility
```

## 5. Use the correct Vagrant provider name

The provider name for VMware desktop usage is:

```text
vmware_desktop
```

So the VMs are started with:

```bash
vagrant up --provider=vmware_desktop
```

## 6. Rocky Linux 9 box

For Rocky Linux 9, I used the Bento box:

```ruby
config.vm.box = "bento/rockylinux-9"
```

## 7. Rocky Linux 10 box

For Rocky Linux 10, I used:

```ruby
config.vm.box = "bento/rockylinux-10"
```

## 8. VMware provider block

The following provider block is the one I used in both Vagrantfiles:

```ruby
vm.vm.provider "vmware_desktop" do |v|
  v.vmx["displayName"] = "#{name}.rhcsa.lab"
  v.vmx["memsize"]     = opts[:mem].to_s
  v.vmx["numvcpus"]    = opts[:cpus].to_s
  v.force_vmware_license = "workstation"
  v.linked_clone = false
  v.allowlist_verified = true
end
```

The most important part is the provider name:

```ruby
vm.vm.provider "vmware_desktop"
```

The other options are specific to my lab setup and troubleshooting experience.

### Notes about these options

```ruby
v.force_vmware_license = "workstation"
```

I used this because at one point Vagrant appeared to behave more like it was using VMware Player behavior instead of VMware Workstation behavior.

```ruby
v.linked_clone = false
```

I used this to keep the setup simpler during the first tests.

```ruby
v.allowlist_verified = true
```

I used this to silence VMX allowlist warnings after checking the generated VMX settings.

## 9. Bring the VMs up

From the directory containing the Vagrantfile, run:

```bash
vagrant up --provider=vmware_desktop
```

This worked for both the Rocky Linux 9 and Rocky Linux 10 lab setups.

To start a specific machine, for example `server`, use:

```bash
vagrant up server --provider=vmware_desktop
```

To connect to the VM:

```bash
vagrant ssh server
```

## 10. VMware Workstation GUI behavior

Vagrant can fully manage the VMs from the command line.

However, VMware Workstation may not automatically show the Vagrant-created VMs in its GUI library.

If I need the GUI, for example to edit hardware, I open the `.vmx` file manually once from the Vagrant machine directory.

The path is usually somewhere below:

```text
.vagrant/machines/<machine-name>/vmware_desktop/
```

For example:

```text
.vagrant/machines/server/vmware_desktop/
```

This is mostly a VMware Workstation GUI registration issue. It does not necessarily mean that Vagrant failed to create or manage the VM.

## 11. Add an extra lab disk manually

For this lab, I did not manage the extra disk through the Vagrantfile.

Instead, I added it manually in VMware Workstation after the VM had already booted successfully once. This was more predictable for my setup.

### Safe workflow

1. Start the server VM once:

   ```bash
   vagrant up server --provider=vmware_desktop
   ```

2. If needed, open the server VM once in VMware Workstation by opening its `.vmx` file.

3. Shut down the VM:

   ```bash
   vagrant halt server
   ```

4. Open **VM Settings** in VMware Workstation.

5. Verify that the original boot disk is still present and untouched.

6. Click **Add...**.

7. Choose **Hard Disk**.

8. Choose **SATA**.

9. Choose **Create a new virtual disk**.

10. Set the new disk size to **2 GB**.

11. Leave **Allocate all disk space now** unchecked.

12. Choose **Store virtual disk as a single file**.

13. Finish and save.

14. Boot the VM again:

    ```bash
    vagrant up server --provider=vmware_desktop
    ```

15. Verify the new disk inside the guest:

    ```bash
    vagrant ssh server
    lsblk
    ```

The new disk should appear as an additional block device, separate from the boot disk.

## Troubleshooting

### VMware breaks after a kernel update

At one point VMware itself was broken before Vagrant even mattered.

This can happen after kernel updates when VMware kernel modules need to be rebuilt.

The fix was:

```bash
sudo vmware-modconfig --console --install-all
```

After that, VMware services and networking started working again on the host.

This was a VMware host problem, not a Vagrantfile problem.

### Vagrant behaves like VMware Player instead of Workstation

If Vagrant appears to behave as if it is using VMware Player behavior, forcing the VMware license mode may help:

```ruby
v.force_vmware_license = "workstation"
```

This is why I kept that line in my provider block.

### VMware Workstation does not show the VM in the GUI

Vagrant-created VMware VMs may not automatically appear in the VMware Workstation library.

The VM can still work fine from Vagrant.

To open it in the GUI, locate the generated `.vmx` file below:

```text
.vagrant/machines/<machine-name>/vmware_desktop/
```

Then open that `.vmx` file manually with VMware Workstation.

### PXE boot or “Operating System not found” after adding a disk

The first time I added an extra disk incorrectly, the VM stopped booting and fell through to PXE with:

```text
Operating System not found
```

The rule for this lab is:

- do not touch the original boot disk
- only add a second small lab disk
- check the existing controller layout before changing anything
- use SATA for the extra lab disk
- verify with `lsblk` after booting the VM again

## Final checklist

The final working setup was:

- download **VMware Workstation Pro 25H2 for Linux**
- select **25H2u1**, or the latest equivalent release
- avoid the old **17.0 for Linux** branch unless you specifically have entitlement for it
- enable the Broadcom download checkbox by opening Terms and Conditions first
- complete the additional verification form if Broadcom asks for it
- install VMware Workstation Pro from the `.bundle`
- install Vagrant
- install the `vagrant-vmware-desktop` plugin
- install the Vagrant VMware Utility
- make sure the `vagrant-vmware-utility` service is running
- use the `vmware_desktop` provider
- use `bento/rockylinux-9` or `bento/rockylinux-10` (just use one of my Vagrantfiles for either of these in my repo)
- add the extra server lab disk manually in VMware Workstation only after the VM already works

## Useful commands

```bash
# Install Vagrant VMware plugin
vagrant plugin install vagrant-vmware-desktop

# Check installed Vagrant plugins
vagrant plugin list

# Check VMware utility service
systemctl status vagrant-vmware-utility

# Rebuild VMware modules after kernel update
sudo vmware-modconfig --console --install-all

# Start all VMs
vagrant up --provider=vmware_desktop

# Start only the server VM
vagrant up server --provider=vmware_desktop

# Stop only the server VM
vagrant halt server

# SSH into the server VM
vagrant ssh server

# Check disks inside the guest
lsblk
```
