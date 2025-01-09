################################################################################
# Fetching Your Public IP for SG Inbound
################################################################################
data "http" "myip" {
  # These public APIs return your IP address in plain text
  url = "https://api.ipify.org"
}

# We'll reference data.http.myip.body to get the raw IP string

################################################################################
# 4.1 Bastion Host Security Group
################################################################################
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security Group for Bastion host"
  vpc_id      = aws_vpc.main_vpc.id

  # Inbound rules
  ingress {
    description      = "Allow SSH from my IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
  }

  # Outbound rules
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "BastionSG"
  }
}

################################################################################
# 4.2 Private Instances Security Group (for Jenkins & App)
################################################################################
resource "aws_security_group" "private_instances_sg" {
  name        = "private-instances-sg"
  description = "SG for Jenkins and App instances in the private subnets"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow inbound from the entire VPC CIDR (e.g., 10.0.0.0/16)
  ingress {
    description      = "Allow all traffic from within VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = [var.vpc_cidr]  # e.g. "10.0.0.0/16"
  }

  # All outbound is allowed
  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrivateInstancesSG"
  }
}

################################################################################
# 4.3 Public Web Security Group (for ALB)
################################################################################
resource "aws_security_group" "public_web_sg" {
  name        = "public-web-sg"
  description = "SG for ALB or public-facing resources"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow HTTP from my IP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
  }

  egress {
    description      = "Allow all outbound"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicWebSG"
  }
}

################################################################################
# 5. EC2 Instances: Bastion, Jenkins, App (Ubuntu 22)
################################################################################

# Bastion host in a public subnet
resource "aws_instance" "bastion" {
  ami                         = "ami-005fc0f236362e99f"  # Ubuntu 22 AMI in us-east-1
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_a.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = "upgrad-test"            # Existing key pair name

  tags = {
    Name = "BastionHost"
  }
}

# Jenkins host in a private subnet
resource "aws_instance" "jenkins" {
  ami                         = "ami-005fc0f236362e99f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_a.id
  vpc_security_group_ids      = [aws_security_group.private_instances_sg.id]
  key_name                    = "upgrad-test"

  tags = {
    Name = "JenkinsServer"
  }
}

# App host in a different private subnet
resource "aws_instance" "app" {
  ami                         = "ami-005fc0f236362e99f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_b.id
  vpc_security_group_ids      = [aws_security_group.private_instances_sg.id]
  key_name                    = "upgrad-test"

  tags = {
    Name = "AppServer"
  }
}

################################################################################
# 6. ALB with Two Public Subnets for HA
################################################################################
resource "aws_lb" "public_alb" {
  name               = "my-public-alb"
  load_balancer_type = "application"
  # >>> IMPORTANT: Provide at least TWO subnets in DIFFERENT AZs <<<
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  security_groups    = [aws_security_group.public_web_sg.id]
  idle_timeout       = 30
  ip_address_type    = "ipv4"

  enable_deletion_protection = false

  tags = {
    Name = "MyPublicALB"
  }
}

resource "aws_lb_target_group" "jenkins_tg" {
  name        = "jenkins-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main_vpc.id
  target_type = "instance"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    protocol            = "HTTP"
    port                = "8080"
    path                = "/"
  }

  tags = {
    Name = "JenkinsTG"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins_tg.arn
  }
}

