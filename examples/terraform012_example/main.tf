###############################################################################
# Providers
###############################################################################
provider "aws" {
  version             = "~> 2.0"
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
}

terraform {
  required_version = ">= 0.12"
}

###############################################################################
# Other Resources
###############################################################################

data "aws_region" "current_region" {
}

resource "random_string" "r_string" {
  length  = 6
  upper   = true
  lower   = false
  number  = false
  special = false
}

module "vpc" {
  source   = "git@github.com:rackspace-infrastructure-automation/aws-terraform-vpc_basenetwork?ref=tf_0.12-upgrade"
  vpc_name = "RedShift-Test-${random_string.r_string.result}"
}

module "redshift_sg" {
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-security_group?ref=tf_0.12-upgrade"
  resource_name = "my_test_sg"
  vpc_id        = "${module.vpc.vpc_id}"
}

#see https://www.terraform.io/docs/providers/aws/d/kms_secrets.html for encryption instruction
data "aws_kms_secrets" "redshift_credentials" {
  secret {
    name    = "master_username"
    payload = "AQICAHgfzIS58fsOTb8qQgAg3HghmNnIfqd4aQP8Kf1VB6NOjwFWysrqwJO1c+ZpbXpEMNbbAAAAYzBhBgkqhkiG9w0BBwagVDBSAgEAME0GCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM3BpoJ9i2pNze49Y3AgEQgCAklZI1nklsur8wdw7iaZuxeMfMJ4O2sFs7j+1tGgWEoA=="
  }

  secret {
    name    = "master_password"
    payload = "AQICAHgfzIS58fsOTb8qQgAg3HghmNnIfqd4aQP8Kf1VB6NOjwEbN+krjYFUIuv+3LVxZHQvAAAAbDBqBgkqhkiG9w0BBwagXTBbAgEAMFYGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMQmXdp/n6Me0jepVtAgEQgCmWkc1osG8bCTOVuahJAaa+JFgSCcpicPClNVoraj7McQ2VJnjhj+n/Dg=="
  }
}

module "internal_zone" {
  source        = "git@github.com:rackspace-infrastructure-automation/aws-terraform-route53_internal_zone?ref=tf_0.12-upgrade"
  zone_name     = "example.com"
  environment   = var.environment
  target_vpc_id = module.vpc.vpc_id
}

resource "aws_eip" "redshift_eip" {
}

resource "aws_iam_policy" "redshift" {
  name        = "test-policy"
  description = "A test policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


module "redshift_test" {
  source                   = "git@github.com:rackspace-infrastructure-automation/aws-terraform-redshift?ref=tf_0.12-upgrade"

  number_of_nodes = 2
  create_route53_record = true
  internal_zone_id = module.internal_zone.internal_hosted_zone_id
  internal_zone_name = module.internal_zone.internal_hosted_name
  use_elastic_ip = true
  elastic_ip = aws_eip.redshift_eip.public_ip
  internal_record_name = "redshiftendpoint"
  publicly_accessible = true
  master_username = data.aws_kms_secrets.redshift_credentials.plaintext["master_username"]
  master_password = data.aws_kms_secrets.redshift_credentials.plaintext["master_password"]
  redshift_instance_class = "dc1.large"
  environment = "Development"
  rackspace_alarms_enabled = true
  subnets = module.vpc.private_subnets
  security_group_list = [module.redshift_sg.redshift_security_group_id]
  db_name = "myredshift"
  cluster_type = "multi-node"
  allow_version_upgrade = true
  storage_encrypted = false
  resource_name = "rs-test-${random_string.r_string.result}"

  additional_tags = {
    TestTag1 = "TestTag1"
    TestTag2 = "TestTag2"
  }

  skip_final_snapshot = true
  final_snapshot_identifier = "MyTestFinalSnapshot"
}

