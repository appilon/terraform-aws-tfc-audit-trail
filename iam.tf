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
data "aws_iam_policy" "ecs-task-execution" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole-TFC-Audit-Trail"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach-ecs-execution-role" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = data.aws_iam_policy.ecs-task-execution.arn
}

# Vector Role
data "aws_iam_policy" "cloudwatch-logs-full" {
  name = "CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "vector-cloudwatch-logs" {
  name               = "vector-cloudwatch-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "attach-vector-cloudwatch-logs" {
  role       = aws_iam_role.vector-cloudwatch-logs.name
  policy_arn = data.aws_iam_policy.cloudwatch-logs-full.arn
}
