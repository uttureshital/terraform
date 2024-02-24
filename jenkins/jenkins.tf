#create vpc and subnet
resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/10"
 
  tags = {
    Name = "${var.my_vpc}-vpc"
    evn = "${var.env}-evn"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "ap-southeast-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.subnet}-subnet"
    evn = "${var.env}-evn"
  }
}

#creating security group

resource "aws_security_group" "my_sg" {
    name = "${var.sg}-sg"
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
        protocol = "TCP"
        from_port = 8080
        to_port = 8080
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
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    tags = {
        Name = "${var.project}-private-instance"
        env =  "${var.env}-evn"
    }
    subnet_id = aws_subnet.my_subnet.id
    user_data =  <<-EOF 
                 #!/bin/bash
                 sudo apt update
                 sudo apt install fontconfig openjdk-17-jre
                 sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
                 https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
                 echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
                 https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
                 /etc/apt/sources.list.d/jenkins.list > /dev/null
                 sudo apt-get update
                 sudo apt-get install jenkins
                 sudo systemctl start jenkins
                 sudo systemctl enable jenkins
                 EOF
}                 