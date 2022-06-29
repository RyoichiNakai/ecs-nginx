# ECSクラスター
resource "aws_ecs_cluster" "www_cluster" {
  name = "default"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Service = var.service_name
  }
}

# nginxタスク
resource "aws_ecs_task_definition" "nginx" {
  family = "nginx"

  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu    = 1024
  memory = 2048

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode = "awsvpc"

  # 起動するコンテナの定義
  # 「nginxを起動し、80ポートを開放する」設定を記述。
  container_definitions = <<EOL
[
  {
    "name": "nginx",
    "image": "public.ecr.aws/nginx/nginx:latest",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "ap-northeast-1",
        "awslogs-group": "/ecs/www_cluster/nginx",
        "awslogs-stream-prefix": "nginx"
      }
    }
  }
]
EOL

  # タスク実行ロール
  execution_role_arn = aws_iam_role.ecs_task_role.arn
}

# CloudWatch Logsの設定
resource "aws_cloudwatch_log_group" "nginx_log" {
  name              = "/ecs/www_cluster/nginx"
  retention_in_days = 30
}

# AmazonECSTaskExecutionRolePolicy の参照
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.service_name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_role_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role_policy.arn
}

# サービス
resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.www_cluster.id
  task_definition = aws_ecs_task_definition.nginx.arn

  # タスクの数
  desired_count = 2

  # ネットワークの設定
  network_configuration {
    subnets          = [for s in aws_subnet.private: s.id]
    security_groups  = [aws_security_group.web.id]
    assign_public_ip = false
  }

  # ターゲットグループの指定
  load_balancer {
    target_group_arn = aws_lb_target_group.www.arn
    container_name   = "nginx"
    container_port   = 80
  }
}
