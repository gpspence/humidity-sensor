# --- IAM Permissions/ Roles ---
data "aws_iam_policy_document" "assume_role" {
  statement}

resource "aws_iam_role" "asg" {
  name               = "asg-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["ec2.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "asg_inline" {
  name = "asg-policy"
  role = aws_iam_role.asg.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asg.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "asg" {
  name = "asg"
  role = aws_iam_role.asg.name

  depends_on = [
    aws_iam_role_policy_attachment.ssm,
    aws_iam_role_policy_attachment.asg_policy
  ]
}


# --- Launch Template ---
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "main" {
  name = "${var.project_name}-main-launch-template"

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20  # GB
      volume_type = "gp3"
    }
  }

  # Prefer throttling bustable performance when out of credits
  credit_specification {
    cpu_credits = "standard"
  }

  # Prevent accidental device termination
  disable_api_termination = true

  ebs_optimized = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.asg.arn
  }

  image_id = data.aws_ami.ubuntu.id

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"

  key_name = "main"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = var.vpc_security_group_ids

  user_data = filebase64("${path.module}/src/cloud-init.sh")
}


# --- ASG ---
resource "aws_autoscaling_group" "main" {
  name                      = "${var.project_name}-asg"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.subnet_ids

  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }
}
