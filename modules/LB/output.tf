output "lb_sg" {
  value = aws_security_group.lb_sg.id
}

output "targetgroup_arn" {
  value = aws_lb_target_group.test_target_group.arn
}

output "alb_public_dns" {
  value = aws_lb.test_lb.dns_name
}