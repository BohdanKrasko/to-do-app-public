variable "pub_key" {
  type    = string
  default = "~/.ssh/ec2.pub"
}

variable "pr_key" {
  type    = string
  default = "~/.ssh/ec2.pem"
}

variable "vpc_name" {
  type    = string
  default = "vpc"
}
variable "instance_count" {
  type    = number
  default = 1
}
variable "igw_name" {
  type    = string
  default = "igw"
}
variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}
