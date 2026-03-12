# Provider AWS — Option A (SSO)
provider "aws" {
  region  = "eu-west-3"
  profile = "tp-devsecops"
}

# Clé SSH
resource "aws_key_pair" "deployer" {
  key_name   = "tp-devsecops-terraform"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Groupe de sécurité
resource "aws_security_group" "web_and_ssh" {
  name        = "web-and-ssh-terraform"
  description = "SSH restreint + HTTP + HTTPS"

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["163.5.3.69/32"] 
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Trafic sortant
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance EC2
resource "aws_instance" "tp_instance" {
  ami             = "ami-05d43d5e94bb6eb95"  # Amazon Linux 2023 — eu-west-3
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.web_and_ssh.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true  # Chiffrement EBS — bonne pratique sécurité
  }

  tags = {
    Name        = "DevSecOps-TP"
    Environment = "student"
    ManagedBy   = "terraform"
  }
}

output "public_ip" {
  description = "IP publique de l'instance"
  value       = aws_instance.tp_instance.public_ip
}

output "ssh_command" {
  description = "Commande SSH prête à l'emploi"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.tp_instance.public_ip}"
}
