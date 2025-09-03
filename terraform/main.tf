provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ci_server" {
  ami           = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI (us-east-1)
  instance_type = "t2.medium"
  key_name      = "your-key-name" # Replace with your key name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    mkdir /home/ec2-user/ci-docker
    cat <<EOC > /home/ec2-user/ci-docker/docker-compose.yml
    version: '3'
    services:
      jenkins:
        image: jenkins/jenkins:lts
        ports:
          - "8080:8080"
        volumes:
          - jenkins_home:/var/jenkins_home
      sonarqube:
        image: sonarqube:latest
        ports:
          - "9000:9000"
        environment:
          - SONAR_JDBC_URL=jdbc:postgresql://db:5432/sonar
          - SONAR_JDBC_USERNAME=sonar
          - SONAR_JDBC_PASSWORD=sonar
        depends_on:
          - db
      db:
        image: postgres:12
        environment:
          - POSTGRES_USER=sonar
          - POSTGRES_PASSWORD=sonar
          - POSTGRES_DB=sonar
      nexus:
        image: sonatype/nexus3
        ports:
          - "8081:8081"
    volumes:
      jenkins_home:
      nexus-data:
    EOC
    chown ec2-user:ec2-user /home/ec2-user/ci-docker/docker-compose.yml
    cd /home/ec2-user/ci-docker
    /usr/local/bin/docker-compose up -d
  EOF

  tags = {
    Name = "ci-server"
  }
}
