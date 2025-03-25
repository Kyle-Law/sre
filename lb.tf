provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_eks_cluster" "main" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}

# IAM Role for Service Account (IRSA)
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "AWSLoadBalancerControllerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "aws_lb_controller_policy_attachment" {
  name       = "aws-load-balancer-controller-attachment"
  roles      = [aws_iam_role.aws_lb_controller_role.name]
  policy_arn = var.aws_lb_controller_policy_arn  # Add this as a variable in variables.tf
}

# Kubernetes Service Account
resource "kubernetes_service_account" "aws_lb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller_role.arn
    }
  }
}

# Helm Installation of AWS Load Balancer Controller
resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  depends_on = [kubernetes_service_account.aws_lb_controller_sa]

  values = [
    yamlencode({
      clusterName    = module.eks.cluster_name
      region         = var.region
      vpcId          = module.eks.vpc_id
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.aws_lb_controller_sa.metadata[0].name
      }
    })
  ]
}

