Kubernetes Cluster Setup Guide
Prerequisites
Infrastructure provisioned for a Kubernetes cluster.
SSH access to the master and worker nodes.
Step 1: Initialize the Kubernetes Cluster on the Master Node
Connect to the master node via SSH:

bash
Copy code
ssh <user>@<master-node-ip>
Initialize the cluster:

bash
Copy code
kubeadm init
If initialization is successful, a kubeadm join command will be displayed. This command will be used by worker nodes to join the Kubernetes cluster. Copy and save this command for later use.
Configure the cluster environment for the master node:

bash
Copy code
export KUBECONFIG=/etc/kubernetes/admin.conf
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
Step 2: Join Worker Nodes to the Kubernetes Cluster
After setting up the master node, each worker node must be joined to the cluster. Follow these steps for each worker node:

SSH into the worker node:

bash
Copy code
ssh <user>@<worker-node-ip>
Use the kubeadm join command (copied from the master node setup) to join the node to the cluster:

bash
Copy code
kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash <hash>
Note: If you did not save the initial kubeadm join command, you can generate a new one on the master node:

bash
Copy code
kubeadm token create --print-join-command
Step 3: Verify Cluster Status
Once all nodes have joined the cluster, verify the status to ensure everything is functioning correctly.

On the master node, list all nodes to see if they are Ready:
bash
Copy code
kubectl get nodes
Step 4: Install CNI for Pod Networking
To enable communication across nodes and to ensure the cluster DNS starts functioning, install a Container Network Interface (CNI) on the master node. We will use Weave as the CNI:

Apply Weave CNI:

bash
Copy code
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
Wait a few minutes, then verify that nodes are in the Ready state by running:

bash
Copy code
kubectl get nodes
Now you are ready to start using your Kubernetes cluster. Happy Kubernetes-ing! 😊