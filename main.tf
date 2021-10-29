resource "aws_instance" "srv01" {
  count         = 1
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  tags = {
    "Name" = "server${count.index + 1}",
    "ENV"  = "DEV"
  }
  user_data = <<-EOF
  #!/bin/bash
  echo "Hello world" > index.html
  nohup busybox httpd -f -p 80 &
  EOF

  vpc_security_group_ids = [aws_security_group.publicwebsg.id]
  depends_on = [
    aws_security_group.publicwebsg
  ]
  key_name = "mandeep" # Created security group manually


  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("privatekey.pem")
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip}"
  }

  provisioner "file" {
    source      = "code.txt"
    destination = "~/mycode.txt"
  }

  provisioner "remote-exec" {
    inline = [
      # "chmod +x script.sh",
      # "./script.sh",
      "cat ~/mycode.txt"
    ]
  }
}

resource "aws_security_group" "publicwebsg" {
  name = "websg-mandeep"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "ipaddress" {
  value = aws_instance.srv01[*].public_ip
}


output "private_ip" {
  value     = aws_instance.srv01[*].private_ip
  sensitive = true
}



resource "aws_security_group" "sg1" {
  description = "Managed by Terraform"
  egress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]
  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]
  name     = "app-alb-security-group"
  tags     = {}
  tags_all = {}
  vpc_id   = "vpc-03ada648584802bf4"
}



resource "aws_security_group" "southsg" {
  provider = aws.apsouth
  ingress = [
    {
      cidr_blocks = [
        "0.0.0.0/0",
      ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
  ]
  name = "app-alb-security-group"
}

data "aws_caller_identity" "ci" {
  provider = aws.apsouth
}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        environment = aws_security_group.southsg.name
    }
}