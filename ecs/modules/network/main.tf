data "aws_vpc" "selected" {
  id = aws_vpc.vpc.id
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    Tier = "Public"
  }
}

data "aws_availability_zones" "available" {
}

resource "aws_internet_gateway" "gw" {

  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.igw_name
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = format("public-%d", count.index)
    Tier = "Public"
  }

}

resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "route-table-public"
  }
}

resource "aws_route_table_association" "subnet-association-public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.route-table.id
}

resource "aws_lb_target_group" "go" {
  name        = "go-target-group"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.selected.id

  health_check {
    path = "/api/task"
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "lb"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "lb"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_lb" "go" {
  name               = "go"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public.*.id

  enable_deletion_protection = false
}

resource "aws_lb_listener" "go" {
  load_balancer_arn = aws_lb.go.arn
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go.arn
  }
}

resource "aws_lb_listener" "go-https" {
  load_balancer_arn = aws_lb.go.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:882500013896:certificate/53cd4f95-c9aa-48a4-a222-a7c4d49246e6"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go.arn
  }
}

resource "aws_service_discovery_private_dns_namespace" "go" {
  name        = "todo"
  vpc         = aws_vpc.vpc.id
}

resource "aws_service_discovery_service" "mongo" {
  name = "mongo"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.go.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}






resource "aws_ecs_cluster" "todo" {
  name = "todo"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "mongo" {
  family                = "mongo"
  container_definitions = file("mongo.json")
  network_mode = "awsvpc"
  execution_role_arn = "arn:aws:iam::882500013896:role/ecsTaskExecutionRole"
  
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
}

resource "aws_ecs_task_definition" "go" {
  family                = "go"
  container_definitions = file("go.json")
  network_mode = "awsvpc"
  execution_role_arn = "arn:aws:iam::882500013896:role/ecsTaskExecutionRole"
  
  requires_compatibilities = ["FARGATE"]
  cpu = 256
  memory = 512
}

resource "aws_ecs_service" "mongo" {
  name            = "mongo"
  cluster         = aws_ecs_cluster.todo.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 1
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    security_groups = [aws_security_group.lb_sg.id]
    assign_public_ip = true
    subnets = aws_subnet.public.*.id
  }

  launch_type = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.mongo.arn
  }
}

resource "aws_ecs_service" "go" {
  name            = "go"
  cluster         = aws_ecs_cluster.todo.id
  task_definition = aws_ecs_task_definition.go.arn
  desired_count   = 1
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.go.arn
    container_name   = "go"
    container_port   = 8080
  }

  network_configuration {
    security_groups = [aws_security_group.lb_sg.id]
    assign_public_ip = true
    subnets = aws_subnet.public.*.id
  }

  launch_type = "FARGATE"
}

resource "aws_route53_record" "go" {
  zone_id = "Z05340611QTGXY4HN6R2I"
  name    = "go.ekstodoapp.tk"
  type    = "A"

  alias {
    name                   = aws_lb.go.dns_name
    zone_id                = aws_lb.go.zone_id
    evaluate_target_health = true
  }
}


///////////

locals {
  s3_origin_id = "www.ekstodoapp.tk"
}




resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "www.ekstodoapp.tk.s3-website.eu-west-3.amazonaws.com"
    origin_id   = local.s3_origin_id
  }

  enabled             = true
  comment             = "Some comment"
  default_root_object = "index.html"

  aliases = ["www.ekstodoapp.tk"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  
  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn = "arn:aws:acm:us-east-1:882500013896:certificate/53cd4f95-c9aa-48a4-a222-a7c4d49246e6"
    ssl_support_method = "vip"
  }
}