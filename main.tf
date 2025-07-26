#------------------------------------------------network------------------------------------------------#
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = var.vpc_name
  }

}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(local.azs)
  cidr_block              = var.subnet_count[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = var.public_subnet_name
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.igw_name
  }

}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }

  tags = {
    Name = var.public_rt_name
  }

}

resource "aws_route_table_association" "public_sub" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


#------------------------------------------------sg------------------------------------------------#
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow SSH inbound"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
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

  tags = {
    Name = "web_sg"
  }
}


#------------------------------------------------ec2------------------------------------------------#
resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet[0].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "ubuntu-instance"
  }
}

resource "aws_instance" "centos" {
  ami                         = data.aws_ami.centos_stream_9.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet[1].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_pair_name
  associate_public_ip_address = true

  tags = {
    Name = "centos-instance"
  }
}


#------------------------------------------------vars------------------------------------------------#
variable "vpc_name" {
  type    = string
  default = "my_vpc_aws"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_name" {
  type    = string
  default = "public_subnet_aws"
}

variable "subnet_count" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_rt_name" {
  type    = string
  default = "public_rt_aws"
}

variable "igw_name" {
  type    = string
  default = "my_igw_aws"
}

variable "key_pair_name" {
  type    = string
  default = "lesson_ansible_key"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}


#--------------------------------------------locals-----------------------------------------------------#
locals {
  common_tags = {
    env = "dev"
    by  = "terraform"
  }
}

locals {
  azs = data.aws_availability_zones.available.names
}


#----------------------------------------------data-----------------------------------------------------#
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20250712"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "centos_stream_9" {
  most_recent = true
  owners      = ["125523088429"]

  filter {
    name   = "name"
    values = ["CentOS Stream 9*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
