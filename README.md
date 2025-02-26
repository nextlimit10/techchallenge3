# techchallenge3

Step-by-Step Guide to Completing Tech Challenge 3: Infrastructure as Code with Terraform and Ansible
This guide will walk you through the process of successfully completing the Infrastructure as Code with Terraform and Ansible tech challenge. Each step includes detailed explanations and best practices to help you complete the challenge efficiently.

Prerequisites
Before starting, ensure you have the following installed on your local machine:
AWS Account (with IAM user having necessary permissions)
Terraform (Install from: Terraform Download)
Ansible (Install via pip install ansible or package manager)
Git (Install from: Git Download)
SSH Key Pair (Generate using ssh-keygen or use an existing one)

Create directories for Terraform and Ansible:
sh

mkdir terraform ansible

Step 2: Provision AWS Infrastructure with Terraform
Why?
Terraform allows us to define infrastructure as code (IaC) to create AWS resources consistently and repeatably.
Actions
Navigate to the Terraform directory:
sh

cd terraform
Create Terraform configuration files:
main.tf (Defines resources)
variables.tf (Defines input variables)
outputs.tf (Defines output values)
provider.tf (Specifies AWS provider)
Updated Terraform Configuration with S3 Bucket
1. provider.tf (Defines AWS Provider)
hcl

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
  region = var.aws_region
}



2. variables.tf (Defines Input Variables)

variable "aws_region" {
  default = "us-west-2"
}


variable "instance_type" {
  default = "t2.micro"
}


variable "key_name" {
  default = "terraform-key"
}


variable "private_key_path" {
  default = "./terraform-key.pem"
}


variable "s3_bucket_name" {
  default = "my-terraform-s3-bucket-is-unique-because-it-has-to-be" # Change this to a globally unique name
}





3. main.tf (Creates Key Pair, Security Group, EC2 Instance, and S3 Bucket)
# Generate SSH Key Pair
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


# Create AWS Key Pair using the generated public key
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}


# Save private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = var.private_key_path
  file_permission = "0600"
}


# Create Security Group
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"


  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access (only use in testing)
  }


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}


# Launch EC2 Instance
resource "aws_instance" "web" {
  ami             = "ami-0606dd43116f5ed57" # Replace with a valid Ubuntu or Amazon Linux AMI
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.web_sg.name]
  associate_public_ip_address = true


  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y && sudo apt install -y python3
              EOF


  tags = {
    Name = "WebServer"
  }
}


# Create S3 Bucket
resource "aws_s3_bucket" "terraform_bucket" {
  bucket = var.s3_bucket_name
}


# Enable Versioning for S3 Bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# Set S3 Bucket Policy (Make Private)
resource "aws_s3_bucket_public_access_block" "bucket_policy" {
  bucket = aws_s3_bucket.terraform_bucket.id


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}




4. outputs.tf (Outputs Public IP, S3 Bucket, and SSH Command)
h

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}


output "s3_bucket_name" {
  description = "S3 Bucket Name"
  value       = aws_s3_bucket.terraform_bucket.id
}


output "ssh_command" {
  description = "SSH Command to connect to EC2"
  value       = "ssh -i ${var.private_key_path} ubuntu@${aws_instance.web.public_ip}"
}


output "ssh_user" {
  value = "ubuntu" # Change to "ubuntu" if using an Ubuntu AMI
}





How to Use the Updated Terraform Code
1. Initialize Terraform
sh

cd terraform
terraform init

2. Apply Terraform Configuration
sh

terraform apply -auto-approve



Before logging into the EC2 make sure to copy the key pair so it will allow you to use ansible. Use this command to copy your key that you made with terraform to the EC2 and change with your actual EC2 ip:

scp -i terraform-key.pem terraform-key.pem ubuntu@<EC2_PUBLIC_IP>:/home/ubuntu/


Log into the EC2 using one of the outputs that you constructed in terraform. It should look like something like this:

ssh -i ./terraform-key.pem ubuntu@34.221.180.247

Run this command to download ansible:
Try running:
sh

sudo apt-get update -y && sudo apt-get install -y ansible


Run this command to check that ansible was installed and currently working in your ec2:


ansible --version

Run this command to change permissions of the private key so it will only be readable by you:

chmod 600 terraform-key.pem

Once the key permissions are fixed, try:
sh

ansible -i inventory.ini all -m ping







Create the inventory.ini file:

nano inventory.ini

Copy this code into the inventory.ini file:


[web]
ec2-instance ansible_host=44.233.7.220 ansible_user=ubuntu ansible_ssh_private_key_file=./terraform-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'





Create an Ansible Playbook (webserver.yml):
yaml
CopyEdit
---
- name: Configure Web Server
  hosts: web
  become: yes
  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Deploy index.html
      copy:
        content: "<h1>Hello, World!</h1>"
        dest: /var/www/html/index.html



Run the Ansible Playbook:
sh

ansible-playbook -i inventory.ini webserver.yml

Verify the Web Page is Running:
Open a browser and go to:
arduino

http://your-ec2-public-ip





