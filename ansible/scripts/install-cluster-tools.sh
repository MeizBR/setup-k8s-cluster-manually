#!/bin/bash

set -e  # Exit on any error

# Step 1: Switch to root user
echo "Running the script as a root user..."

# Step 2: Configure persistent loading of modules
echo "Setting up persistent module loading for containerd..."
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Step 3: Load kernel modules at runtime
echo "Loading kernel modules..."
sudo modprobe overlay
sudo modprobe br_netfilter

# Step 4: Update IPTables settings
echo "Configuring sysctl for Kubernetes networking..."
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Step 5: Apply sysctl settings without reboot
echo "Applying sysctl settings..."
sudo sysctl --system

# Step 6: Add Docker GPG key
echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Step 7: Add Docker repository
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 8: Install containerd
echo "Installing containerd..."
sudo apt-get update && sudo apt-get install -y containerd.io

# Step 9: Configure containerd for systemd cgroup management
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Step 10: Reload, restart, and enable containerd
echo "Reloading and restarting containerd..."
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 11: Update apt package index and install dependencies for Kubernetes
echo "Installing dependencies for Kubernetes..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl

# Step 12: Add Kubernetes GPG key
echo "Adding Kubernetes GPG key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Step 13: Add Kubernetes repository
echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Step 14: Install kubelet, kubeadm, and kubectl
echo "Installing kubelet, kubeadm, and kubectl..."
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl

# Step 15: Hold Kubernetes packages at current version
echo "Holding kubelet, kubeadm, and kubectl at their installed versions..."
sudo apt-mark hold kubelet kubeadm kubectl

# Step 16: Enable kubelet service
echo "Enabling kubelet service..."
sudo systemctl enable kubelet

echo "Setup complete! Docker, containerd, and Kubernetes tools are installed and configured."
