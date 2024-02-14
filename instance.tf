provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "my-instance" {
  ami           = "ami-0449c34f967dbf18a"
  instance_type = "t2.micro"
  key_name = "demo"
  vpc_security_group_ids = "sg-0b83a9a554862d712"
  tags = {
    Name = "demo-instance"
  }
}
