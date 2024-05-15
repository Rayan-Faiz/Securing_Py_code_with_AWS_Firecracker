#!/bin/bash

# Install required packages
sudo apt update
sudo apt install -y wget unzip build-essential

# Download and install Firecracker
wget https://github.com/firecracker-microvm/firecracker/releases/download/v0.25.1/firecracker-v0.25.1-x86_64 -O firecracker
chmod +x firecracker
sudo mv firecracker /usr/local/bin/

# Download and install firectl
wget https://github.com/firecracker-microvm/firectl/releases/download/v0.3.1/firectl-v0.3.1-x86_64 -O firectl
chmod +x firectl
sudo mv firectl /usr/local/bin/

# Download a sample rootfs and kernel image
wget https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
wget https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4

# Create a Firecracker configuration file
cat << EOF > hello-config.json
{
  "boot-source": {
    "kernel_image_path": "hello-vmlinux.bin",
    "boot_args": "console=ttyS0 noapic reboot=k panic=1 pci=off"
  },
  "drives": [
    {
      "drive_id": "rootfs",
      "path_on_host": "hello-rootfs.ext4",
      "is_root_device": true,
      "is_read_only": false
    }
  ],
  "machine-config": {
    "vcpu_count": 1,
    "mem_size_mib": 128
  },
  "logger": {
    "log_fifo": "log.fifo",
    "metrics_fifo": "metrics.fifo"
  },
  "network-interfaces": [
    {
      "iface_id": "eth0",
      "guest_mac": "AA:FC:00:00:00:01",
      "host_dev_name": "tap100"
    }
  ]
}
EOF

# Launch Firecracker with firectl
sudo firectl --firecracker-binary=/usr/local/bin/firecracker --kernel=hello-vmlinux.bin --root-drive=hello-rootfs.ext4 --kernel-opts="console=ttyS0 noapic reboot=k panic=1 pci=off" --tap-device=tap100 --tap-ip=192.168.100.1/24 --firecracker-config=hello-config.json
