# Get the latest Bitnami Tomcat AMI
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

# Declare instance_type variable
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# VPC Module
module "My_Blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Security Group Module
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "My_Blog"
  description = "Security group for blog instance"
  vpc_id      = module.My_Blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules        = ["all-all"]
  egress_cidr_blocks  = ["0.0.0.0/0"]
}

# EC2 Instance
resource "aws_instance" "blog" {
  ami                    = data.aws_ami.app_ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [module.blog_sg.security_group_id]
  subnet_id              = module.My_Blog_vpc.public_subnets[0]
  associate_public_ip_address = true

  tags = {
    Name = "Learning_Terraform"
  }
}
