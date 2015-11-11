# ===========
# CREDENTIALS
# ===========
provider "aws" {
    access_key  = "${var.access_key}"
    secret_key  = "${var.secret_key}"
    region      = "eu-west-1"
}

# =====================
# CREATE VPC AND SUBNET
# =====================
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
        Name = "main"
    }
}

resource "aws_route_table" "routes" {
    vpc_id = "${aws_vpc.main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gw.id}"
    }

    tags {
        Name = "main"
    }
}

resource "aws_route_table_association" "rta" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.routes.id}"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags {
        Name = "Main"
    }
}

# ===================
# CREATE HUB INSTANCE
# ===================
resource "aws_instance" "selenium-hub" {
    ami = "ami-0365ba70"
    instance_type = "t1.micro"
    subnet_id = "${aws_subnet.main.id}"
    private_ip = "10.0.1.100"
    iam_instance_profile = "${aws_iam_instance_profile.selenium_profile.name}"
}

# ===================================================================
# CREATE NODE INSTANCES IN AUTOSCALING GROUP WITH IN AND OUT POLICIES
# ===================================================================
resource "aws_launch_configuration" "node_launch_conf" {
    image_id = "ami-6364bb10"
    instance_type = "t1.micro"
}

resource "aws_autoscaling_group" "nodes" {
    vpc_zone_identifier = ["${aws_subnet.main.id}"]
    name = "selenium-nodes"
    max_size = 2
    min_size = 1
    launch_configuration = "${aws_launch_configuration.node_launch_conf.name}"

}

resource "aws_autoscaling_policy" "node_scaling_policy_up" {
  name = "selenium-nodes-up"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.nodes.name}"
}

resource "aws_autoscaling_policy" "node_scaling_policy_down" {
  name = "selenium-nodes-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.nodes.name}"
}

resource "aws_cloudwatch_metric_alarm" "selenium_queue" {
    alarm_name = "selenium-queue-monitor"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "selenium-queue"
    namespace = "selenium"
    period = "60"
    statistic = "Average"
    threshold = "1"
    alarm_description = "This metric monitor selenium grid queue length"
    alarm_actions = ["${aws_autoscaling_policy.node_scaling_policy_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "selenium_node_idle" {
    alarm_name = "selenium-node-idle"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "1"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "300"
    statistic = "Average"
    threshold = "10"
    alarm_description = "This metric monitor ec2 cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.node_scaling_policy_down.arn}"]
}

# =============================
# SECURITY GROUPS AND IAM ROLES
# =============================
resource "aws_security_group_rule" "allow_all_4444" {
    type = "ingress"
    from_port = 0
    to_port = 4444
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = "${aws_vpc.main.default_security_group_id}"
}

resource "aws_iam_instance_profile" "selenium_profile" {
    name = "selenium_profile"
    roles = ["${aws_iam_role.selenium_role.name}"]
}

resource "aws_iam_role" "selenium_role" {
    name = "selenium_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "selenium_policy" {
    name = "selenium_policy"
    role = "${aws_iam_role.selenium_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:Describe*",
        "cloudwatch:*",
        "logs:*",
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
