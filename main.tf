data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]


  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type

   vpc_security_group_ids      = [module.blog_sg.security_group_id]
   associate_public_ip_address = true
   subnet_id                   = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "Learning Terraform"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name                = "blog-alb"

  load_balancer_type = "application"

  vpc_id              = module.blog_vpc.vpc_id
  subnets             = module.blog_vpc.public_subnets
  security_groups     = [module.blog_sg.security_group_id]

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = [
    {
      port                   = 80
      protocol               = "HTTP"
      default action = {
        type = "forward"
      }
      target_group_index     = 0
    }
  ]

  target_groups = [
    {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 8080
      target_type      = "instance"
      targets = [
        {
          target_id      = aws_instance.blog.id
          port        = 8080
        }
      ] 
    }
  ]

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}

  module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  vpc_id = module.blog_vpc.vpc_id
  name   = "blog"

  ingress_rules       = ["https-443-tcp","http-80-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]

}

