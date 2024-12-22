provider "aws" {
  region = "us-west-2" # Adjust region as needed
  access_key = "AKIA5G2VGXQCHL5NBMN3"
  secret_key = "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"
}

# Security Group for the Spring Boot instance
resource "aws_security_group" "spring_boot_sg" {
  name        = "spring_boot_sg"
  description = "Security group for Spring Boot instance"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for the PostgreSQL instance
resource "aws_security_group" "postgres_sg" {
  name        = "postgres_sg"
  description = "Security group for PostgreSQL instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # You can restrict this to only the Spring Boot IP later
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elastic IP for Spring Boot EC2 instance
resource "aws_eip" "spring_boot_eip" {
  instance = aws_instance.spring_boot_instance.id
}

# Elastic IP for PostgreSQL EC2 instance
resource "aws_eip" "postgres_eip" {
  instance = aws_instance.postgres_instance.id
}

# EC2 instance for Spring Boot Application
resource "aws_instance" "spring_boot_instance" {
  ami           = "ami-04dd23e62ed049936" # Amazon Linux 2 AMI (update based on region)
  instance_type = "t2.micro"
  key_name      = "your-key-name"  # Ensure you have a key pair created in your AWS account

  security_groups = [aws_security_group.spring_boot_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y java-1.8.0-openjdk
              sudo mkdir -p /opt/springboot
              cd /opt/springboot
              # Assuming your Spring Boot app is packaged as a jar file and stored in an S3 bucket
              aws s3 cp s3://your-bucket/springboot-app.jar /opt/springboot/springboot-app.jar
              nohup java -jar /opt/springboot/springboot-app.jar &
            EOF

  tags = {
    Name = "Spring Boot Instance"
  }
}

# EC2 instance for PostgreSQL Database
resource "aws_instance" "postgres_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (update based on region)
  instance_type = "t2.micro"
  key_name      = "your-key-name"  # Ensure you have a key pair created in your AWS account

  security_groups = [aws_security_group.postgres_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y postgresql-server postgresql-contrib
              sudo postgresql-setup initdb
              sudo systemctl start postgresql
              sudo systemctl enable postgresql
              sudo -u postgres psql -c "CREATE USER springuser WITH PASSWORD 'springpassword';"
              sudo -u postgres psql -c "CREATE DATABASE springdb;"
              sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE springdb TO springuser;"
            EOF

  tags = {
    Name = "Postgres Instance"
  }
}

# Output the public IPs of both instances
output "spring_boot_public_ip" {
  value = aws_eip.spring_boot_eip.public_ip
}

output "postgres_public_ip" {
  value = aws_eip.postgres_eip.public_ip
}
