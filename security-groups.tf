resource "aws_security_group" "worker_group_mgmt" {
  name_prefix = "worker_group_mgmt"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group_rule" "cluster_ingress_http" {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    security_group_id = aws_security_group.worker_group_mgmt.id
    type = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_tls" {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    security_group_id = aws_security_group.worker_group_mgmt.id
    type = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_ingress_admin" {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"

    security_group_id = aws_security_group.worker_group_mgmt.id
    type = "ingress"
}