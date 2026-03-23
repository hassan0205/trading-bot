########################################
# 1. AWS Provider
########################################
provider "aws" {
  region = "eu-north-1"
}

########################################
# 2. Security Group
########################################
resource "aws_security_group" "bot_sg" {
  name        = "bot-sg"
  description = "Allow SSH and Kubernetes NodePort"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes NodePort range
  ingress {
    description = "K8s NodePort"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

########################################
# 3. EC2 Instance (AlmaLinux)
########################################
resource "aws_instance" "bot_server" {
  ami           = "ami-00212882da11367e3"
  instance_type = "t3.micro"

  key_name = "hassan"

  vpc_security_group_ids = [aws_security_group.bot_sg.id]

  ########################################
  # 4. Auto Setup Script
  ########################################
  user_data = <<-EOF
              #!/bin/bash

              # Update system
              dnf update -y

              # Install packages
              dnf install -y docker git curl

              # Start Docker
              systemctl start docker
              systemctl enable docker

              # Install Minikube
              curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube-linux-amd64 /usr/local/bin/minikube

              # Install kubectl
              curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl
              install kubectl /usr/local/bin/kubectl

              # Add user to docker group
              usermod -aG docker ec2-user

              EOF

  tags = {
    Name = "Trading-Bot-Server"
  }
}

########################################
# 5. Output Public IP
########################################
output "public_ip" {
  value = aws_instance.bot_server.public_ip
}
