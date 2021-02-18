variable "vpc_name" {
  type = string
}
variable "instance_count" {
  type = number
}
variable "igw_name" {
  type = string
}
variable "cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

