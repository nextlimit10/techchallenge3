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
