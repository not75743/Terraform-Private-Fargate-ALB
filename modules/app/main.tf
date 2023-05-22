resource "aws_iam_role" "task_execution_role" {
  name = "${var.system_name}_${var.environment}_task_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_iam_role" "task_role" {
  name = "${var.system_name}_${var.environment}_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "task_role_policy" {
  name   = "${var.system_name}_${var.environment}_task_role_policy"
  policy = file("../../modules/app/policy.json")
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_role_policy.arn
}

resource "aws_security_group" "app_sg" {
  name   = "${var.system_name}_${var.environment}_app-sg"
  vpc_id = var.vpcid

  ingress {
    from_port       = var.app-port
    to_port         = var.app-port
    protocol        = "tcp"
    security_groups = [var.lb_sg]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.system_name}_${var.environment}_${var.container-name}-sg"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.system_name}_${var.environment}_cluster"
}

resource "aws_ecs_task_definition" "app" {
  family = "${var.system_name}_${var.environment}_${var.container-name}"
  container_definitions = templatefile("../../modules/app/container_definitions.json",
    {
      container-name  = var.container-name,
      container-image = var.container-image
    }
  )
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  requires_compatibilities = ["FARGATE"]
  tags = {
    "Name" = "${var.system_name}_${var.environment}_${var.container-name}"
  }
}

resource "aws_ecs_service" "service" {
  name                   = "${var.system_name}_${var.environment}_${var.container-name}_service"
  cluster                = aws_ecs_cluster.cluster.id
  desired_count          = 1
  enable_execute_command = true
  launch_type            = "FARGATE"
  network_configuration {
    subnets = [
      var.private1,
      var.private2
    ]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.targetgroup_arn
    container_name   = var.container-name
    container_port   = "80"
  }

  task_definition = aws_ecs_task_definition.app.arn
  tags = {
    "Name" = "${var.system_name}_${var.environment}_${var.container-name}_service"
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count,
    ]
  }
}

resource "aws_cloudwatch_log_group" "log" {
  name              = "/ecs/logs/${var.container-name}"
  retention_in_days = 1
}