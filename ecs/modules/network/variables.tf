variable "vpc_name" {
  type = string
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


