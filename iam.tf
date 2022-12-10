# Assume role policy doc for ECS Task
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

# Some accounts have a default ecsTaskExecutionRole, some do not
# see https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html#create-task-execution-role
data "aws_iam_policy" "ecs-task-execution-role" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

# SSM needed for secrets
resource "aws_iam_policy" "ssm-get-parameters" {
  name = "ssm-get-parameters-${local.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ecs-task-execution-role" {
  name               = "ecs-task-execution-role-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach-ecs-task-execution-role" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = data.aws_iam_policy.ecs-task-execution-role.arn
}

resource "aws_iam_role_policy_attachment" "attach-ssm-get-parameters" {
  role       = aws_iam_role.ecs-task-execution-role.name
  policy_arn = aws_iam_policy.ssm-get-parameters.arn
}

# Vector Role
data "aws_iam_policy" "cloudwatch-logs-full" {
  name = "CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "vector" {
  name               = "vector-cloudwatch-logs-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach-vector-cloudwatch-logs" {
  role       = aws_iam_role.vector.name
  policy_arn = data.aws_iam_policy.cloudwatch-logs-full.arn
}
