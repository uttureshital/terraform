provider "aws" {
    region = "ap-southeast-2"
}

#create vpc and subnet

resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/16"
 
  tags = {
    Name = "jenkins-vpc"
    }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "192.168.16.0/20"
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public"
    }
}

#creating security group

resource "aws_security_group" "my_sg" {
    name = "jkn-sg"
    description = "allow jenkins and ssh"
    vpc_id = aws_vpc.my_vpc.id
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
        from_port = 22
        to_port = 22
    }
    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
    egress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
    
}

#creating instance

resource "aws_instance" "instance" {
    ami = "ami-04f5097681773b989"
    instance_type = "t2.micro"
    key_name = "shital"
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    tags = {
        Name = "jenkins-instance"
        
    }
    subnet_id = aws_subnet.my_subnet.id
    
    user_data = <<EOF
                 #!/bin/bash

                 sudo apt update

                 sudo apt install fontconfig openjdk-17-jre -y

                 wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -

                 sudo sh -c "echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list"

                 sudo apt-get update -y

                 sudo apt-get install -y jenkins

                 sudo systemctl start jenkins

                 sudo systemctl enable jenkins

                 EOF
}

   