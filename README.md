# Firecracker MicroVM

## Overview

Firecracker is an open-source virtualization technology that provides a lightweight and secure environment for running cloud-based workloads. It is designed specifically for running microservices and functions in a serverless environment. Firecracker uses KVM (Kernel-based Virtual Machine) to create and manage lightweight VMs called microVMs, which are optimized for security and speed.

## How Firecracker Helps Secure Programs

1. **Isolation**: Firecracker provides strong isolation between microVMs, ensuring that each workload runs in its own secure environment without interference from other workloads.
   
2. **Minimal Attack Surface**: Due to its minimalistic design, Firecracker has a small attack surface, reducing the risk of security vulnerabilities.

3. **Fast Startup**: Firecracker microVMs boot up quickly, reducing the window of exposure to potential attacks.

4. **Immutable Infrastructure**: Firecracker encourages the use of immutable infrastructure patterns, where VMs are treated as disposable entities. This reduces the risk of configuration drift and makes it easier to maintain a secure environment.

## Installing Firecracker

### Prerequisites

Before installing Firecracker, ensure you have the following prerequisites installed:

- Linux kernel version 4.14 or later
- KVM enabled in your kernel configuration
- `curl` and `jq` packages installed (for downloading and configuring Firecracker)
- Golang 1.11+

### Installation Steps To Firecracker and Firectl

1. **Download Firecracker Binary**:

   ```bash
   curl -LOJ https://github.com/firecracker-microvm/firecracker/releases/download/v0.13.0/firecracker-v0.13.0
   mv firecracker-v0.13.0 firecracker
   chmod +x firecracker
   
2. **Copy to $PATH**:

   ```bash
   sudo cp firecracker /usr/bin/

3. **Set read/write access to KVM**:

   ```bash
   sudo setfacl -m u:${USER}:rw /dev/kvm

4. **Verify Installation**:

   ```bash
   firecracker -V

You should see the version numbers of Firecracker printed to the console if the installation was successful.

5. **Build firectl binary**:

Currently firectl doesn’t have any release yet, so we need build it using go
      
    sudo yum install -y git
    git clone https://github.com/firecracker-microvm/firectl
    cd firectl
    make

6. **Copy binary to $PATH**:

   ```bash
   sudo cp firectl /usr/bin/

7. **Check if firectl installed successfully**:

   ```bash
   firectl -h

## Running Programs on Firecracker MicroVM

To run Python programs on a Firecracker microVM, follow these steps:

1. **Create a Root Filesystem Image**: You'll need a root filesystem image containing a minimal Linux environment and Python installed. You can use tools like debootstrap or buildroot to create this image.

   ```bash
   curl -fsSL -o /tmp/hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
   curl -fsSL -o /tmp/hello-rootfs.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4

3. **Start Firecracker with the RootFS Image**:
   
    ```bash
    ./firecracker --api-sock /tmp/firecracker.sock

4. **Launch a MicroVM Instance**:

   ```bash
   curl --unix-socket /tmp/firecracker.sock -i -X PUT 'http://localhost/machine-config' -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{ "vcpu_count": 2, "mem_size_mib": 512 }'

5. **Attach the RootFS Image**:

   ```bash
   curl --unix-socket /tmp/firecracker.sock -i -X PUT 'http://localhost/drives/rootfs' -H 'Accept: application/json' -H 'Content-Type: application/json -d '{ "drive_id": "rootfs", "path_on_host": "<path_to_rootfs_image>", "is_root_device": true, "is_read_only": false }'

6. **Or Download them ALTERNATIVELY**:

   ```bash
   curl -fsSL -o /tmp/hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bincurl -fsSL -o /tmp/hello-rootfs.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4

7. **Start the MicroVM with Firectl ALTERNATIVELY**:

   ```bash
   firectl --kernel=/tmp/hello-vmlinux.bin --root-drive=/tmp/hello-rootfs.ext4 --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw"

8. **Connect to the MicroVM**:

Create a tap interface

    sudo ip tuntap add tap0 mode tap
    sudo ip addr add 172.20.0.1/24 dev tap0
    sudo ip link set tap0 up

Set your main interface device. If you have different name check it with ifconfig command

    DEVICE_NAME=eth0

Provide iptables rules to enable packet forwarding

    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo iptables -t nat -A POSTROUTING -o $DEVICE_NAME -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i tap0 -o $DEVICE_NAME -j 

Get mac of the tap device

    MAC="$(cat /sys/class/net/tap0/address)"

Provide interface to the MicroVM when starting ( — tap-device)

    firectl --kernel=/tmp/hello-vmlinux.bin --root-drive=/tmp/hello-rootfs.ext4 --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off nomodules rw" --tap-device=tap0/$MAC

Setup inside guest vm

    ifconfig eth0 up && ip addr add dev eth0 172.20.0.2/24
    ip route add default via 172.20.0.1 && echo "nameserver 8.8.8.8" > /etc/resolv.conf

You can now run Python programs within the Firecracker microVM.

## Conclusion

Firecracker provides a lightweight and secure environment for running cloud workloads, making it an ideal choice for deploying and securing programs in a serverless environment. By following the installation and usage instructions provided in this README, you can leverage Firecracker to run Python programs securely in microVMs.






