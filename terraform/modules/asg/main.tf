# --- IAM Permissions/ Roles ---
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "asg" {
  name               = "asg"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = var.secret_arns
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = var.kms_key_arns
  }
}

resource "aws_iam_policy" "asg" {
  name = "asg-policy"
  description = "Policy for ASG launch template"
  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" {
  role = aws_iam_role.asg.name
  policy_arn = aws_iam_policy.asg.arn
}

resource "aws_iam_instance_profile" "asg" {
  name = "asg"
  role = aws_iam_role.asg.name
}


# --- Launch Template ---
resource "aws_launch_template" "main" {
  name = "main"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20  # GB
    }
  }

  # Prefer throttling bustable performance when out of credits
  credit_specification {
    cpu_credits = "standard"
  }

  # Prevent accidental device stopping through the console
  disable_api_stop        = true
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    name = ""
  }

  image_id = "ami-test"

  instance_initiated_shutdown_behavior = "terminate"

  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t3.micro"

  kernel_id = "test"

  key_name = "test"

  license_specification {
    license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_performance_options {
    bandwidth_weighting = "vpc-1"
  }

  network_interfaces {
    associate_public_ip_address = true
  }

  placement {
    availability_zone = "eu-west-2a"
  }

  ram_disk_id = "test"

  vpc_security_group_ids = ["sg-12345678"]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "test"
    }
  }

  user_data = filebase64("${path.module}/example.sh")
}


# --- ASG ---
resource "aws_placement_group" "main" {
  name     = "main"
  strategy = "cluster"
}

resource "aws_autoscaling_group" "main" {
  name                      = "foobar3-terraform-test"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 4
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_configuration.foobar.name
  vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  initial_lifecycle_hook {
    name                 = "foobar"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"

    notification_metadata = jsonencode({
      foo = "bar"
    })

    notification_target_arn = "arn:aws:sqs:us-east-1:444455556666:queue1*"
    role_arn                = "arn:aws:iam::123456789012:role/S3Access"
  }

  tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "lorem"
    value               = "ipsum"
    propagate_at_launch = false
  }
}
