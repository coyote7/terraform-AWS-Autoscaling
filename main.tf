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
  image_id            = ""
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