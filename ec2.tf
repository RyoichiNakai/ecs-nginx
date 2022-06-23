# EC2インスタンス
resource "aws_instance" "web" {
  # Amazon Linux2
  ami = "ami-0f310fced6141e627"

  instance_type = "t2.micro"

  subnet_id = aws_subnet.private[0].id

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ssm.name

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = "10"
  }

  tags = {
    Name = "${var.service_name}-web"
  }
}

# AWSインスタンスプロファイルの設定
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
} 

resource "aws_iam_role" "role" {
  name               = "web-instance-ssm"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "ssm" {
  name = "web-profile"
  role = aws_iam_role.role.name
}
