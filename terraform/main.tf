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
