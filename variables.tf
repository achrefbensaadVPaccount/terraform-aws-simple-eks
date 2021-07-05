variable "profile" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

# If this variable is an empty string, the
# log group name will be var.cluster_name
variable "log_group_name" {
  type    = string
  default = null
}

variable "cluster_version" {
  type = string
  default = "1.20"
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "use_calico_cni" {
  type    = bool
  default = false
}

# Dont tags subnets unless needed
# To avoid unwanted shared ressources tags mutation
variable "tag_subnets" {
  default = false
}

# Allow subnets specification from cascading parent modules
variable "cascading_subnets" {
  default = false
}

variable "public_subnets" {
  default = []
}

variable "private_subnets" {
  default = []
}

# Allow the use of both public and private subnets for the cluster
variable "allow_public_private_subnets" {
  default = false
}