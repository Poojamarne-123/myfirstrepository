terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.12.0"
    }
  }
}

provider "aws" {
    region ="us-east-1"
}
resource "aws_vpc" "MyVpc" {
  cidr_block = "30.0.0.0/16"
}
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.MyVpc.id
  cidr_block = "30.0.1.0/24"
  availability_zone ="us-east-1a"
}
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.MyVpc.id
  cidr_block = "30.0.2.0/24"
  availability_zone ="us-east-1b"
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.MyVpc.id
}
resource "aws_route_table" "MRT" {
  vpc_id = aws_vpc.MyVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}
resource "aws_eip" "nat_eip" {
  
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "ngw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table" "CRT" {
  vpc_id = aws_vpc.MyVpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "CRT"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.MRT.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.CRT.id
}
