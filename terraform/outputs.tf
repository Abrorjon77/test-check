output "instance_public_ip" {
  value = aws_instance.ci_server.public_ip
}
