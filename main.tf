#creates an aws lauch configuration ,autoscaling group and load balancers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.16"
    }
  }
  required_version = "~>1.5.4"
}
provider "aws" {
  region  = "us-east-1"
  profile = "ronte"
}
#creates a launch config
resource "aws_launch_configuration" "example-config" {
  image_id        = ""
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.example2-sg.id]
  user_data       = <<-EOF
     echo "Welcome to my  Webpage">index.html
     nohup busybox -f -p ${var.server-port} &
     EOF

}

#security group for the launch config
resource "aws_security_group" "example2-sg" {
  ingress {
    from_port   = var.server-port
    to_port     = var.server-port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_autoscaling_group" "example-ASG" {
  launch_configuration = aws_launch_configuration.example-config.name
  #specify subnets
  vpc_zone_identifier = data.aws_subnets.example-subnets.ids
  min_size            = 2
  max_size            = 4
  tag {
    key                 = "Name"
    value               = "example-SG"
    propagate_at_launch = true
  }
}
#gets default vpc
data "aws_vpc" "example-vpc" {
  default = true

}
#gets subnets in default vpc
data "aws_subnets" "example-subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.example-vpc.id]
  }

}

#include load balancer
resource "aws_lb" "example-lb" {
  name               = "example-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-securitygrp.id]

}
#creates security group
resource "aws_security_group" "lb-securitygrp" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
#creates target group
resource "aws_alb_target_group" "example-targetgrp" {
  name     = "example-targetgrp"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.example-vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 5
    matcher             = 200
    timeout             = 3
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }


}
resource "aws_lb_listener" "example-listener" {
  load_balancer_arn = aws_lb.example-lb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type = "fixed-response"
    fixed_response {
      message_body = "error 404 ...page not found"
      content_type = "text/plain"
      status_code  = 404

    }
  }

}
resource "aws_lb_listener_rule" "example-listener-ruler" {
  listener_arn = aws_lb_listener.example-listener.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.example-targetgrp.arn
  }



}