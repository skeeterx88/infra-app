module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = "challenge-pedro-verissimo"
    GithubRepo  = "devops"
    GithubOrg   = "verissimo"
  }

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-g1"
      instance_type                 = "t2.small"
      additional_userdata           = "Small Server"
      asg_max_size                  = 5
      asg_min_size                  = 2
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt.id]
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
