# Create VPC
resource "aws_vpc" "main" {
  cidr_block       = var.VPC_CIDR

  tags = {
    Name = "nxt"
  }
}
------------------------------------------------------------
#Create public & private subnets
resource "aws_subnet" "NXT_Pub_Sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.NXT_Pub_Sub1
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = "us-east-1a"
  tags = {
    Name = "NXT-Pub-Sub1"
  }
}

resource "aws_subnet" "NXT_Pub_Sub2" { 
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.NXT_Pub_Sub2
  map_public_ip_on_launch = var.mapPublicIP
  availability_zone       = "us-east-1b"
  tags = {
    Name = "NXT-Pub-Sub2"
  }
}

resource "aws_subnet" "NXT_Pri_Sub1" { 
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.NXT_Pri_Sub1
  availability_zone = "us-east-1a"
  tags = {
    Name = "NXT-Pri-Sub1"
  }
}

resource "aws_subnet" "NXT_Pri_Sub2" { 
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.NXT_Pri_Sub2
  availability_zone = "us-east-1b"
  tags = {
    Name = "NXT-Pri-Sub2"
  }
}
-----------------------------------------------------------------------------
#Create Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "NXT-IGW
	"
  }
}
-------------------------------------------------------------------
#Create Elastic IP

resource "aws_eip" "EIP_NATGW_1" {
  domain   = "vpc"
}

resource "aws_eip" "EIP_NATGW_2" {
  domain   = "vpc"
}

resource "aws_elb" "nxt_app_elb" {
  name               = "nxt-app-elb"
  availability_zones = ["us-east-1a", "us-east-1b"]
  subnets			 = [aws_subnet.NXT_Pub_Sub1.id, aws_subnet.NXT_Pub_Sub2.id]

  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [aws_instance.nxt-assignment.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nxt-app-elb"
  }
}
---------------------------------------------------------------------------------------------------------
#Create NAT Gateways

resource "aws_nat_gateway" "NXT-NGW_1" {
  allocation_id = aws_eip.EIP_NATGW_1.id
  subnet_id     = aws_subnet.NXT_Pub_Sub1.id

  tags = {
    Name = "NATGW-1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "NXT-NGW_2" {
  allocation_id = aws_eip.EIP_NATGW_2.id
  subnet_id     = aws_subnet.NXT_Pub_Sub2.id

  tags = {
    Name = "NATGW-2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
----------------------------------------------------------------------------------------------------------
#Create EKS Cluster resources

resource "aws_eks_cluster" "NXT_Cluster" {
  name     = "NXT_Cluster"
  role_arn = aws_iam_role.NXT_EKS_ROLE.arn

  vpc_config {
    subnet_ids = [aws_subnet.NXT_Pri_Sub1.id, aws_subnet.NXT_Pri_Sub2.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.NXT-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.NXT-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.NXT_Cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.NXT_Cluster.certificate_authority[0].data
}


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

resource "aws_iam_role" "NXT_EKS_ROLE" {
  name               = "NXT_EKS_ROLE"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "NXT-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.NXT_EKS_ROLE.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "NXT-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.NXT_EKS_ROLE.name
}
-----------------------------------------------------------------------------------------------------------------------
#Create EKS Node Group resources

resource "aws_eks_node_group" "NXT_NG" {
  cluster_name    = aws_eks_cluster.NXT_Cluster.name
  node_group_name = "nxt-app"
  node_role_arn   = aws_iam_role.NG_ROLE.arn
  subnet_ids      = aws_subnet.NXT_Pri_Sub1.id, aws_subnet.NXT_Pri_Sub2.id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.NXT-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.NXT-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.NXT-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "NG_ROLE" {
  name = "eks-node-group-nxt"

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

resource "aws_iam_role_policy_attachment" "NXT-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.NG_ROLE.name
}

resource "aws_iam_role_policy_attachment" "NXT-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.NG_ROLE.name
}

resource "aws_iam_role_policy_attachment" "NXT-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.NG_ROLE.name
}
----------------------------------------------------------------------------------------------------------------------
#Create RDS

resource "aws_db_instance" "nxt-database" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
----------------------------------------------------------------------------------------------------------------------
# Create ECR

resource "aws_ecr_repository" "nxt-repo" {
  name                 = "nxt-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
-------------------------------------------------------------------------------------------------------------