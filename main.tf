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


module "blog_sg" {
source  = "terraform-aws-modules/security-group/aws"
version = "5.3.0"
name    = "My_Blog"
description = "Security group for blog instance"


vpc_id              = module.My_Blog_vpc.vpc_id

ingress_rules       = ["http-80-tcp","https-443-tcp"]
ingress_cidr_blocks = ["0.0.0.0/0"]


egress_rules       = ["all-all"]
egress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "blog" {
  ami                         = data.aws_ami.app_ami.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [module.blog_sg.security_group_id]
  subnet_id                   = module.My_Blog_vpc.public_subnets[0]
  associate_public_ip_address = true  


  tags = {
    Name = "HelloWorld"
  }
}
<<<<<<< HEAD
=======






>>>>>>> 3209c7f3aeaf161875ae2f7a43c9c1efe5c589