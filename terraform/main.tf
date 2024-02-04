terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = " ~> 3.27"
    }
  }

  required_version = ">= 1.2"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

###########################################################
########### RESOURCE BLOCKS ###############################
###########################################################


# Data source for AMI
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}


# Data source to use the default VPC


# Adding SSH key to Amazon EC2
resource "aws_key_pair" "clo835-host-kp" {
  key_name   = "clo835-host-kp"
  public_key = file("${var.prefix}-host-kp.pub")
}

# Security Group
resource "aws_security_group" "host-ec2-sg" {
  name = "security group from terraform"

  ingress {
    description = "SSH from the internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "80 from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Step 12 - EC2 creation
resource "aws_instance" "clo835-host-EC2" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.clo835-host-kp.key_name
  vpc_security_group_ids      = [aws_security_group.host-ec2-sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/install_docker.sh")
  iam_instance_profile        = "LabInstanceProfile"

  tags = merge(var.default_tags,
    {
      "Name" = "${var.prefix}-host-EC2"
    }
  )
}



# ECR
resource "aws_ecr_repository" "clo835-ecr" {
  name                 = "jculloa-ecr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


/*
# IAM instance profile

resource "aws_iam_instance_profile" "ec2toecr" {
  name = "ec2toecr"
  role = "arn:aws:iam::796109909635:instance-profile/LabInstanceProfile"
}




resource "aws_iam_instance_profile" "ec2toecr" {
  name = "ec2toecr"
  role = aws_iam_role.labrole.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "labrole" {
  name               = "labrole"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
*/