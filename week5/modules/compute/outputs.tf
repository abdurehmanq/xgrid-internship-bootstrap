output "alb_dns_name" { value = aws_lb.wp_alb.dns_name }
output "alb_arn_suffix" { value = aws_lb.wp_alb.arn_suffix }
output "asg_name" { value = aws_autoscaling_group.wp_asg.name }