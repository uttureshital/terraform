provider "aws" {
    region = "ap-south-1"
}

#create role

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cluster-role" {
  name               = "var.cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role" "node-role" {
  name = "var.node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-role.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-role.name
}

#create vpc 

resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/20"
  tags = {
    Name = "var.my-vpc"
  }
} 

#create subnet 

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/11"
  map_public_ip_on_launch = true
  tags = {
    Name = "var.public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/17"

  tags = {
    Name = "var.private-subnet"
  }
}
#create internet gateway

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "var.my-igw"
  }
}

#create rounte table

resource "aws_route" "my_route" {
  route_table_id            = aws_vpc.my-vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my-igw.id
}

#create security group 

resource "aws_security_group" "my-sg" {
  name        = "var.my-sg"
  description = "allow inbond rule"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "var.my-sg"
  }
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
  
#create eks cluster

resource "aws_eks_cluster" "my-cluster" {
  name     = "var.my-cluster"
  role_arn = aws_iam_role.cluster-role.arn

  vpc_config {
    subnet_ids = [aws_subnet.private.id, aws_subnet.public.id]
  }

  
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
  ]
}

#create node group

resource "aws_eks_node_group" "my-node-group" {
  cluster_name    = aws_eks_cluster.my-cluster.name
  node_group_name = "shital-node"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = [
     aws_subnet.public.id,
     aws_subnet.private.id
    ]

 capacity_type = "ON_DEMAND"
  instance_types = ["t3.micro"]
  scaling_config {
    desired_size = 2
    min_size = 1
    max_size = 4
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [ 
    aws_iam_role_policy_attachment.my-node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.my-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.my-node-AmazonEKS_CNI_Policy
  ]
}

resource "aws_nat_gateway" "my-nat-gateway" {
  allocation_id = aws_eip.my_eip.id
  subnet_id     = aws_subnet.private.id
}

# Elastic IP for NAT Gateway

resource "aws_instance" "my_instance" {
  ami           = "ami-0014ce3e52359afbd"  
  instance_type = "t3.micro"                
  subnet_id     = aws_subnet.public.id
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.my_instance.id
}