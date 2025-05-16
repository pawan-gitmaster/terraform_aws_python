
resource "aws_key_pair" "my-key" {
    key_name = "key1"
    public_key = file("/home/ubuntu_admin/.ssh/id_rsa.pub")
}

resource "aws_vpc" "my-vpc" {
  cidr_block = var.CIDR
}

resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.my-vpc.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
}

resource "aws_route_table_association" "rt-association" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_security_group" "sg" {
  name = "security-group1"
  vpc_id = aws_vpc.my-vpc.id
  ingress {
    description = "HTTp from outside"
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH to instance"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "my-instance" {
  ami = var.image
  instance_type = var.instance_type
  key_name = aws_key_pair.my-key.key_name
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id = aws_subnet.public-subnet.id

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = file("/home/ubuntu_admin/.ssh/id_rsa")
  }

  provisioner "file" {
    source = "/mnt/c/Users/PAWAN/Desktop/aws/app.py"
    destination = "/home/ubuntu/app.py"
  }

  provisioner "remote-exec" {
    inline = [ 
        "echo 'Hello from the remote instance'",
        "sudo apt update -y",
        "cd /home/ubuntu",
        "sudo apt install python3-flask",
        "sudo python3 app.py &"
     ]
  }
}

