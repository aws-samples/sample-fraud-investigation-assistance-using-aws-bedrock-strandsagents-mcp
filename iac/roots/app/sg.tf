// Copyright 2025 Amazon.com and its affiliates; all rights reserved.
// This file is Amazon Web Services Content and may not be duplicated or distributed without permission.

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${local.id}-alb-security-group"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Ingress TCP traffic on ports 80-8080"
    from_port       = 80
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.strands_mcp_sg.id]
  }

  egress {
    description     = "Egress TCP traffic on ports 80-8080"
    from_port       = 80
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks_sg" {
  #checkov:skip=CKV_AWS_382:Some tasks communicate with internet and need permissive outbound
  name        = "${local.id}-ecs-tasks-security-group"
  description = "Allow inbound traffic from the load balancer only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Traffic from ALB security group"
    from_port       = 80
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description     = "Allow out all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name = "${local.id}-db-sg"
  description = "limited access sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "Allow inbound traffic from specific lambdas on DB port"
    protocol  = "tcp"
    from_port = 5533
    to_port   = 5533
    security_groups = [aws_security_group.db_lambda_sg.id]
  }
}

# Lambda security group
resource "aws_security_group" "db_lambda_sg" {
  name        = "${local.id}-db-lambda-sg"
  description = "Security group for Lambda functions that interact with DB"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow HTTP outbound traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS outbound traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic to DB port"
    from_port   = 5533
    to_port     = 5533
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "strands_mcp_sg" {
  name_prefix = "${local.id}-strands-mcp-client-lambda"
  description = "Security group for Strands Lambda function that uses MCP Clients"
  vpc_id      = module.vpc.vpc_id

  egress {
    description     = "Allow TCP traffic to VPC"
    from_port       = 80
    to_port         = 433
    protocol        = "tcp"
    cidr_blocks     = [var.vpc_cidr_block]
  }

  egress {
    description       = "Allow HTTPS traffic outbound"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    #cidr_blocks     = [var.vpc_cidr_block]
    cidr_blocks     = ["0.0.0.0/0"]
  }
}