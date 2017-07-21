provider "aws" {
  region     = "us-east-1"
}

resource "aws_vpc" "Venkata-TerraVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags {
    Name = "Venkata-TerraVPC"
  }
}

resource "aws_subnet" "Venkata-PublicSubnet-1" {
  vpc_id     = "${aws_vpc.Venkata-TerraVPC.id}"
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "Venkata-PublicSubnet-1"
  }
}

resource "aws_subnet" "Venkata-PublicSubnet-2" {
  vpc_id     = "${aws_vpc.Venkata-TerraVPC.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags {
    Name = "Venkata-PublicSubnet-2"
  }
}

resource "aws_subnet" "Venkata-PrivateSubnet-1" {
  vpc_id     = "${aws_vpc.Venkata-TerraVPC.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "Venkata-PrivateSubnet-1"
  }
}

resource "aws_subnet" "Venkata-PrivateSubnet-2" {
  vpc_id     = "${aws_vpc.Venkata-TerraVPC.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags {
    Name = "Venkata-PrivateSubnet-2"
  }
}

resource "aws_route_table_association" "PublicSubnet1RouteTableAssociation" {
  subnet_id      = "${aws_subnet.Venkata-PublicSubnet-1.id}"
  route_table_id = "${aws_route_table.VenkataPublicRT.id}"
}

resource "aws_route_table_association" "PublicSubnet2RouteTableAssociation" {
  subnet_id      = "${aws_subnet.Venkata-PublicSubnet-2.id}"
  route_table_id = "${aws_route_table.VenkataPublicRT.id}"
}

resource "aws_route_table_association" "PrivateSubnet1RouteTableAssociation" {
  subnet_id      = "${aws_subnet.Venkata-PrivateSubnet-1.id}"
  route_table_id = "${aws_route_table.VenkataPrivateRT.id}"
}

resource "aws_route_table_association" "PrivateSubnet2RouteTableAssociation" {
  subnet_id      = "${aws_subnet.Venkata-PrivateSubnet-2.id}"
  route_table_id = "${aws_route_table.VenkataPrivateRT.id}"
}

resource "aws_internet_gateway" "Venkata-TerraIGW" {
  vpc_id = "${aws_vpc.Venkata-TerraVPC.id}"
}

resource "aws_eip" "Venkata-TerraEIP" {
  vpc      = true
}

resource "aws_nat_gateway" "Venkata-TerraNGW" {
  allocation_id = "${aws_eip.Venkata-TerraEIP.id}"
  subnet_id     = "${aws_subnet.Venkata-PublicSubnet-1.id}"
  depends_on = ["aws_internet_gateway.Venkata-TerraIGW"]
}

resource "aws_route_table" "VenkataPublicRT" {
  vpc_id = "${aws_vpc.Venkata-TerraVPC.id}"

  tags {
    Name = "VenkataPublicRT"
  }
}

resource "aws_route_table" "VenkataPrivateRT" {
  vpc_id = "${aws_vpc.Venkata-TerraVPC.id}"

  tags {
    Name = "VenkataPrivateRT"
  }
}

resource "aws_route" "Venkata-terraPubroute" {
  route_table_id            = "${aws_route_table.VenkataPublicRT.id}"
  destination_cidr_block    = "0.0.0.0/0"	
  gateway_id = "${aws_internet_gateway.Venkata-TerraIGW.id}"
}

resource "aws_route" "Venkata-terraPriroute" {
  route_table_id            = "${aws_route_table.VenkataPrivateRT.id}"
  destination_cidr_block    = "0.0.0.0/0"	
  nat_gateway_id = "${aws_nat_gateway.Venkata-TerraNGW.id}"
}

resource "aws_network_interface" "publicENI" {
  subnet_id       = "${aws_subnet.Venkata-PublicSubnet-2.id}"
  security_groups = ["${aws_security_group.Venkata-PublicSG.id}"]
}
resource "aws_instance" "Venkata-TerraBastion" {
  ami = "ami-a4c7edb2"
  instance_type = "t2.micro"
  availability_zone = "us-east-1b"
  key_name = "${var.key_name}"
  ebs_block_device {
    device_name = "/dev/sdm"
    volume_size = 8
    volume_type = "io1"
    iops = 100
    delete_on_termination = true
   } 
   network_interface {
     network_interface_id = "${aws_network_interface.publicENI.id}"
     device_index = 0
  }
   tags {
    Owner = "${var.owner}"
    Name = "Venkata-TerraBastion"
    Environment = "${var.environment}"
    Project = "${var.project}"
    ExpirationDate = "${var.expirationdate}"
  }
}
resource "aws_network_interface" "privateENI" {
  subnet_id       = "${aws_subnet.Venkata-PrivateSubnet-1.id}"
  security_groups = ["${aws_security_group.Venkata-PrivateSG.id}"]
}
resource "aws_instance" "Venkata-TerraBitnami" {
  ami = "ami-89f68a9f"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "${var.key_name}"
  ebs_block_device {
    device_name = "/dev/sdm"
    volume_size = 8
    volume_type = "io1"
    iops = 100
    delete_on_termination = true
  }
  network_interface {
     network_interface_id = "${aws_network_interface.privateENI.id}"
     device_index = 0
  }
  tags {
    Owner = "${var.owner}"
    Name = "Venkata-TerraBitnami"
    Environment = "${var.environment}"
    Project = "${var.project}"
    ExpirationDate = "${var.expirationdate}"
  }
}
resource "aws_network_interface" "privateNI" {
  subnet_id       = "${aws_subnet.Venkata-PrivateSubnet-1.id}"
  security_groups = ["${aws_security_group.Venkata-PrivateSG.id}"]
}
resource "aws_instance" "Venkata-TerraLAMPStack" {
  ami = "ami-a4c7edb2"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "${var.key_name}"
  user_data = "${data.template_file.user_data.rendered}"
  ebs_block_device {
    device_name = "/dev/sdm"
    volume_size = 8
    volume_type = "io1"
    iops = 100
    delete_on_termination = true
  }
  network_interface {
     network_interface_id = "${aws_network_interface.privateNI.id}"
     device_index = 0
  }
  tags {
    Owner = "${var.owner}"
    Name = "Venkata-TerraLAMPStack"
    Environment = "${var.environment}"
    Project = "${var.project}"
    ExpirationDate = "${var.expirationdate}"
  }
}

# Create a new load balancer
resource "aws_elb" "Venkata-TerraELB" {
  name               = "Venkata-TerraELB"
  security_groups = ["${aws_security_group.Venkata-PublicSG.id}"]
  subnets = ["${aws_subnet.Venkata-PublicSubnet-1.id}" , "${aws_subnet.Venkata-PublicSubnet-2.id}" ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    target              = "TCP:22"
    interval            = 10
  }

  instances                   = ["${aws_instance.Venkata-TerraBitnami.id}" , "${aws_instance.Venkata-TerraLAMPStack.id}" ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "Venkata-TerraELB"
  }
}

resource "aws_security_group" "Venkata-PublicSG" {
  vpc_id = "${aws_vpc.Venkata-TerraVPC.id}"
  name        = "Venkata-PublicSG"
  description = "Allow MyIP inbound traffic"

  ingress {
    cidr_blocks = ["72.196.48.126/32"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["72.196.48.126/32"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["72.196.48.126/32"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  tags {
    Name = "Venkata-PublicSG"
  }
}

resource "aws_security_group" "Venkata-PrivateSG" {
  vpc_id = "${aws_vpc.Venkata-TerraVPC.id}"
  name        = "Venkata-PrivateSG"
  description = "Allow MyIP inbound traffic"

  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }

  ingress {
    cidr_blocks = ["10.0.0.0/16"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  }
  tags {
    Name = "Venkata-PrivateSG"
  }
}

data "template_file" "user_data" {
  template = "${file("user_data/user_config.txt")}"
}
