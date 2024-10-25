output "master_node_public_ip" {
    value = module.master-nodes.master-node-instance.public_ip
}

output "worker_node_public_ips" {
    value = [for i in module.worker-nodes.worker-node-instance : i.public_ip]
}
