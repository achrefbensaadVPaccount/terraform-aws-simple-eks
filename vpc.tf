# Not every VPC have a name
# Using VPC id will be more convenient 
data "aws_vpc" "eks_vpc" {
  id = var.vpc_id
}

# Get all subnets and their ids
data "aws_subnet_ids" "all_subnets_ids" {
  vpc_id = var.vpc_id
}


data "aws_subnet" "all_subnets" {
  for_each = data.aws_subnet_ids.all_subnets_ids.ids
  id       = each.value
  depends_on = [
    data.aws_vpc.eks_vpc,
    data.aws_subnet_ids.all_subnets_ids
  ]
}

# TODO: use aws_ec2_tag instead of kubectl

resource "null_resource" "tag_subnets" {
  triggers = {
    subnet_ids   = join(" ", setunion(local.private, local.public))
    cluster_name = var.cluster_name
    region       = var.region
    profile      = var.profile
  }

  # To avoid unwanted shared ressources tags mutation
  count = var.tag_subnets ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      aws ec2 create-tags \
        --resource ${self.triggers.subnet_ids} \
        --tags "Key=kubernetes.io/cluster/${self.triggers.cluster_name},Value=shared" \
        --region=${self.triggers.region} \
        --profile ${self.triggers.profile}
    EOT

    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws ec2 delete-tags \
        --resource ${self.triggers.subnet_ids} \
        --tags "Key=kubernetes.io/cluster/${self.triggers.cluster_name},Value=shared" \
        --region=${self.triggers.region} \
        --profile ${self.triggers.profile}
    EOT

    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.check_aws_credentials_are_available]
}
