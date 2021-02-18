output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = data.aws_subnet_ids.public.ids
}

output "private_subnets" {
  value = data.aws_subnet_ids.private.ids
}

