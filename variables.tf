variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "aws_lb_controller_policy_arn" {
  description = "The ARN of the AWSLoadBalancerControllerIAMPolicy"
  type        = string
}
