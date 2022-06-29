# ターゲットグループ
resource "aws_lb_target_group" "www" {
  name             = "default-www"
  port             = 80
  protocol         = "HTTP"
  target_type      = "ip"
  vpc_id           = aws_vpc.main.id

  # 登録解除の遅延
  deregistration_delay = 10

  # 登録された後にリクエストを開始する猶予時間
  slow_start = 0

  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  # ヘルスチェック
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 29
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }

  tags = {
    Service = var.service_name
  }
}

# ターゲットグループにEC2をアタッチ
# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = aws_lb_target_group.www.arn
#   target_id        = aws_instance.web.private_ip
#   port             = 80
# }

# ALB
resource "aws_lb" "www" {
  name               = "default-www"
  internal           = false # 内部で使用しないため無効。
  load_balancer_type = "application"
  ip_address_type    = "ipv4" 

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [for s in aws_subnet.public : s.id]

  idle_timeout               = 60    # デフォルトの60秒を設定。
  enable_deletion_protection = false # Terraformで削除したいため無効。
  enable_http2               = true

  tags = {
    Service = var.service_name
  }
}

# ALB リスナー
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.www.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.www.arn
  }
}
