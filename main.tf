# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
variable "vpc_id" {
  type = string
  default = ""
}

variable "name" {
  type = string
  default = ""
}

data "aws_vpc" "default" {
  default = true
}

data "aws_vpc" "selected" {
  id = (var.vpc_id == "" ? data.aws_vpc.default.id : var.vpc_id)
}

locals {
  prefix = (var.name == "" ? "" : "${var.name}--")
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

# Database Instances
resource "aws_security_group" "database_instances" {
  name        = "${local.prefix}database-instances"
  description = "Allow HTTP/HTTPS inbound traffic from the internet"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "database_instances_out" {
  security_group_id = aws_security_group.database_instances.id
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "postgresql_from_web_servers" {
  security_group_id = aws_security_group.database_instances.id
  description       = "Allow PostgreSQL traffic from Web Servers"
  type              = "ingress"
  source_security_group_id = aws_security_group.web_servers.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
}

resource "aws_security_group_rule" "postgresql_from_workers" {
  security_group_id = aws_security_group.database_instances.id
  description       = "Allow PostgreSQL traffic from Workers"
  type              = "ingress"
  source_security_group_id = aws_security_group.workers.id
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
}

# Redis Instances
resource "aws_security_group" "redis_instances" {
  name        = "${local.prefix}redis-instances"
  description = "Allow Redis traffic"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "redis_from_web_servers" {
  security_group_id = aws_security_group.redis_instances.id
  description       = "Allow Redis traffic from Web Servers"
  type              = "ingress"
  source_security_group_id = aws_security_group.web_servers.id
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
}

resource "aws_security_group_rule" "redis_from_workers" {
  security_group_id = aws_security_group.redis_instances.id
  description       = "Allow Redis traffic from Workers"
  type              = "ingress"
  source_security_group_id = aws_security_group.workers.id
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
}

# Elasticsearch Instances
resource "aws_security_group" "elasticsearch_instances" {
  name        = "${local.prefix}elasticsearch-instances"
  description = "Allow HTTPS traffic from Web Servers and Workers"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "elasticsearch_from_web_servers" {
  security_group_id = aws_security_group.elasticsearch_instances.id
  description       = "Allow HTTPS traffic from Web Servers"
  type              = "ingress"
  source_security_group_id = aws_security_group.web_servers.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "elasticsearch_from_workers" {
  security_group_id = aws_security_group.elasticsearch_instances.id
  description       = "Allow HTTPS traffic from Workers"
  type              = "ingress"
  source_security_group_id = aws_security_group.workers.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

# Load Balancers
resource "aws_security_group" "load_balancers" {
  name        = "${local.prefix}load-balancers"
  description = "Allow HTTP/HTTPS inbound traffic from the internet"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "load_balancers_out" {
  security_group_id = aws_security_group.load_balancers.id
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancers_http" {
  security_group_id = aws_security_group.load_balancers.id
  description       = "HTTP"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "load_balancers_https" {
  security_group_id = aws_security_group.load_balancers.id
  description       = "HTTPS "
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Web Servers
resource "aws_security_group" "web_servers" {
  name        = "${local.prefix}web-servers"
  description = "Allow HTTP/HTTPS from load balancers, and SSH from the internet"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "web_servers_out" {
  security_group_id = aws_security_group.web_servers.id
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_servers_ipv6_out" {
  security_group_id = aws_security_group.web_servers.id
  description       = "Outbound traffic (IPv6)"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "web_servers_ssh" {
  security_group_id = aws_security_group.web_servers.id
  description       = "SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_servers_ssh_ipv6" {
  security_group_id = aws_security_group.web_servers.id
  description       = "SSH (IPv6)"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "web_servers_http" {
  security_group_id = aws_security_group.web_servers.id
  description       = "HTTP (from load balancers)"
  type              = "ingress"
  source_security_group_id = aws_security_group.load_balancers.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

resource "aws_security_group_rule" "web_servers_https" {
  security_group_id = aws_security_group.web_servers.id
  description       = "HTTPS (from load balancers)"
  type              = "ingress"
  source_security_group_id = aws_security_group.load_balancers.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "web_servers_health_check" {
  security_group_id = aws_security_group.web_servers.id
  description       = "Health Check (from load balancers)"
  type              = "ingress"
  source_security_group_id = aws_security_group.load_balancers.id
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
}

resource "aws_security_group" "workers" {
  name        = "${local.prefix}workers"
  description = "Allow SSH from the internet, and local traffic from web servers"
  vpc_id = data.aws_vpc.selected.id
}

resource "aws_security_group_rule" "workers_out" {
  security_group_id = aws_security_group.workers.id
  description       = "Outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "workers_ipv6_out" {
  security_group_id = aws_security_group.workers.id
  description       = "Outbound traffic (IPv6)"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "workers_ssh" {
  security_group_id = aws_security_group.workers.id
  description       = "SSH"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "workers_ssh_ipv6" {
  security_group_id = aws_security_group.workers.id
  description       = "SSH (IPv6)"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "workers_local_traffic" {
  security_group_id = aws_security_group.workers.id
  description       = "Local traffic from web servers"
  type              = "ingress"
  source_security_group_id = aws_security_group.web_servers.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}

# Output
output "web_servers" {
  value = aws_security_group.web_servers
}

output "workers" {
  value = aws_security_group.workers
}

output "load_balancers" {
  value = aws_security_group.load_balancers
}

output "database_instances" {
  value = aws_security_group.database_instances
}

output "redis_instances" {
  value = aws_security_group.redis_instances
}

output "elasticsearch_instances" {
  value = aws_security_group.elasticsearch_instances
}
