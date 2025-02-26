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
