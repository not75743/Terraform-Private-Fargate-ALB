# ALB用セキュリティグループ
resource "aws_security_group" "lb_sg" {
  name   = "${var.system_name}_${var.environment}_lb-sg"
  vpc_id = var.vpcid

  ingress {
    from_port   = var.lb-port
    to_port     = var.lb-port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.system_name}_${var.environment}_lb-sg"
  }
}

# ALBのターゲットグループの作成
resource "aws_lb_target_group" "test_target_group" {
  name        = "${var.system_name}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpcid
  target_type = "ip"
}

# ALBのリスナーの作成
resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test_target_group.arn
  }
}

# ALBの作成
resource "aws_lb" "test_lb" {
  name               = "${var.system_name}-${var.environment}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [var.public1, var.public2]
}