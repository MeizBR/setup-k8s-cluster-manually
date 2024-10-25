resource "aws_security_group" "master-node-sg" {
    name = "master-node-sg"
    vpc_id = var.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.ip_addresses_range
    }

    # Kubernetes API server
    ingress {
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # etcd server client API
    ingress {
        from_port   = 2379
        to_port     = 2380
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Kubelet API
    ingress {
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # kube-scheduler
    ingress {
        from_port   = 10251
        to_port     = 10251
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # kube-controller-manager
    ingress {
        from_port   = 10252
        to_port     = 10252
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
        Name: "${var.env_prefix}-master-node-sg"
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

resource "aws_key_pair" "master-node-deployer-key" {
    key_name   = var.key_name
    public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "master-node" {
    ami = data.aws_ami.latest_ubuntu_image.id
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.master-node-sg.id]
    availability_zone = var.subnet_avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.master-node-deployer-key.key_name

    connection {
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(var.private_key_location)
        host     = self.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "echo 'Changing the hostname to master'",
            "sudo hostnamectl set-hostname master",
            "echo 'master' | sudo tee /etc/hostname",
            "echo '127.0.0.1 master' | sudo tee -a /etc/hosts",
            "echo 'Hostname changed successfully !'"
        ]
    }

    tags = {
        Name: "${var.env_prefix}-master-node"
    }
}