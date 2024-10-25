resource "aws_security_group" "worker-nodes-sg" {
    name = "worker-nodes-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.ip_addresses_range
    }

    # Kubelet API
    ingress {
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # NodePort Services
    ingress {
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name: "${var.env_prefix}-worker-nodes-sg"
    }
}

data "aws_ami" "latest_ubuntu_image" {
    owners = ["099720109477", "137112412989"]
    filter {
        name = "name"
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

data "aws_key_pair" "k8s-cluster-existing-key" {
  key_name = "k8s-cluster"
}

resource "aws_instance" "worker-node" {
    ami = data.aws_ami.latest_ubuntu_image.id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.worker-nodes-sg.id]
    availability_zone = var.subnet_avail_zone

    associate_public_ip_address = true
    key_name = data.aws_key_pair.k8s-cluster-existing-key.key_name

    count = 2

    connection {
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(var.private_key_location)
        host     = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "echo 'Changing the hostname to worker'",
            "sudo hostnamectl set-hostname worker",
            "echo 'worker' | sudo tee /etc/hostname",
            "echo '127.0.0.1 worker' | sudo tee -a /etc/hosts",
            "echo 'Hostname changed successfully !'"
        ]
    }

    tags = {
        Name: "${var.env_prefix}-worker-node"
    }
}