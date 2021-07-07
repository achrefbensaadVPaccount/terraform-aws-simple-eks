locals {
  worker-mng-name = "${var.cluster_name}-mng-worker-${random_string.worker-mng-name.result}"
}

resource "random_string" "worker-mng-name" {
  length  = 4
  upper   = false
  number  = true
  lower   = true
  special = false
}

resource "aws_eks_node_group" "worker-node-group" {
  cluster_name         = var.cluster_name
  node_group_name      = local.worker-mng-name
  node_role_arn        = aws_iam_role.worker_role.arn
  subnet_ids           = local.private
  capacity_type        = "SPOT"
  force_update_version = false

  launch_template {
    name    = aws_launch_template.bottlerocket_lt.name
    version = aws_launch_template.bottlerocket_lt.latest_version
  }

  scaling_config {
    desired_size = var.worker_desired_size
    max_size     = var.worker_max_size
    min_size     = var.worker_min_size
  }

  depends_on = [aws_launch_template.bottlerocket_lt,
    aws_eks_cluster.cluster,
  ]
  lifecycle {
    create_before_destroy = true
  }
}


locals {
  instance_profile_arn = aws_iam_role.worker_role
  root_device_mappings = tolist(data.aws_ami.bottlerocket_image.block_device_mappings)[0]
  autoscaler_tags      = var.cluster_autoscaler ? { "k8s.io/cluster-autoscaler/enabled" = "true", "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned" } : {}
  bottlerocket_tags    = { "Name" = "eks-node-aws_eks_cluster.cluster.name" }
  tags                 = merge(var.tags, { "kubernetes.io/cluster/${var.cluster_name}" = "owned" }, local.autoscaler_tags, local.bottlerocket_tags)
}


data "template_file" "bottlerocket_config" {
  template = file("${path.module}/bottlerocket_config.toml.tpl")
  vars = {
    cluster_name                 = var.cluster_name
    cluster_endpoint             = aws_eks_cluster.cluster.endpoint
    cluster_ca_data              = aws_eks_cluster.cluster.certificate_authority[0].data
    admin_container_enabled      = true
    admin_container_superpowered = true
    admin_container_source       = ""
  }
}

data "aws_ssm_parameter" "bottlerocket_image_id" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}/x86_64/latest/image_id"
}

data "aws_ami" "bottlerocket_image" {
  owners = ["amazon"]
  filter {
    name   = "image-id"
    values = [data.aws_ssm_parameter.bottlerocket_image_id.value]
  }
}


resource "aws_launch_template" "bottlerocket_lt" {
  name_prefix            = var.cluster_name
  update_default_version = true
  block_device_mappings {
    device_name = local.root_device_mappings.device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = local.root_device_mappings.ebs.volume_type
      delete_on_termination = true
    }
  }

  instance_type = var.instance_size

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
  }

  image_id  = data.aws_ami.bottlerocket_image.id
  user_data = base64encode(data.template_file.bottlerocket_config.rendered)

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
  tags = local.tags

  lifecycle {
    create_before_destroy = true
  }
}