resource "aws_lb" "main" {
  name            = var.app_name
  subnets         = aws_subnet.public_subnet.*.id
  security_groups = [aws_security_group.movies-app.id]
}

resource "aws_lb_target_group" "frontend" {
  name        = "frontend"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.movies-app.id
  target_type = "ip"
}

resource "aws_lb_target_group" "backend" {
  name        = "backend"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.movies-app.id
  target_type = "ip"
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.main.arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
