terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  backend "s3" {
    encrypt = true
    bucket = "state-bucket-teste"
    region = "us-west-2"
    key    = "teste.tfstate"
  }

  required_version = ">= 0.14.9"
}

# - Criar sqs dead letter OK
# - Criar sqs OK
# - Criar policies OK
# - Criar lambda OK

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

module "sqs_dead_letter" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs"

  name = var.sqs_deadletter_queue_name
}

module "sqs" {
  source = "github.com/terraform-aws-modules/terraform-aws-sqs"

  name = var.sqs_queue_name
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.sqs_dead_letter.sqs_queue_arn
    maxReceiveCount     = 4
  })
}

resource "aws_iam_policy" "read_sqs_policy" {
  name        = "ReceiveMessageSQSPolicy"
  path        = "/"
  description = "Receive message policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Effect": "Allow",
      "Resource": "${module.sqs.sqs_queue_arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "receive_message_role" {
  name = "ReceiveMessageSQSRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_receive_message_sqs" {
  role       = "${aws_iam_role.receive_message_role.name}"
  policy_arn = "${aws_iam_policy.read_sqs_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "attach_logging" {
  role       = "${aws_iam_role.receive_message_role.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

module "lambda_function_existing_package_local" {
  source = "github.com/terraform-aws-modules/terraform-aws-lambda"

  function_name = "my-lambda-existing-package-local"
  description   = "My awesome lambda function"
  handler       = "lambda-processor"
  runtime       = "go1.x"

  create_role = false
  lambda_role = "${aws_iam_role.receive_message_role.arn}"

  create_package         = false
  local_existing_package = "../bin/linux_amd64/lambda-processor.zip"
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = "${module.sqs.sqs_queue_arn}"
  function_name    = "${module.lambda_function_existing_package_local.lambda_function_arn}"
  batch_size       = "1"
}
