# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-policy"
  role   = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::your-bucket-name/*"
      }
    ]
  })
}


# Create S3 Buckets
resource "aws_s3_bucket" "print_bucket" {
  bucket = "your-unique-identifier-print-bucket"  # Change this
}

resource "aws_s3_bucket" "email_bucket" {
  bucket = "your-unique-identifier-email-bucket"  # Change this
}

resource "aws_s3_bucket" "fax_bucket" {
  bucket = "your-unique-identifier-fax-bucket"  # Change this
}

# Lambda Functions
resource "aws_lambda_function" "request_handler" {
  function_name = "request_handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "request-handler.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename      = "${path.module}/../lambdas/request-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/request-handler.zip")

  environment {
    variables = {
      ACTION_BUCKET = "print-bucket"
    }
  }
}

resource "aws_lambda_function" "print_lambda" {
  function_name = "print_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "print-lambda.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename      = "${path.module}/../lambdas/print-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/print-lambda.zip")

  environment {
    variables = {
      BUCKET_NAME = "print-bucket"
    }
  }
}

resource "aws_lambda_function" "email_lambda" {
  function_name = "email_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "email-lambda.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename      = "${path.module}/../lambdas/email-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/email-lambda.zip")

  environment {
    variables = {
      BUCKET_NAME = "email-bucket"
    }
  }
}
resource "aws_lambda_function" "fax_lambda" {
  function_name = "fax_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "fax-lambda.handler"
  runtime       = "nodejs18.x"
  timeout       = 30

  filename      = "${path.module}/../lambdas/fax-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/fax-lambda.zip")

  environment {
    variables = {
      BUCKET_NAME = "fax-bucket"
    }
  }
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "trigger_rule" {
  name        = "event_trigger_rule"
  event_pattern = jsonencode({
    "source": ["custom.event"],
    "detail-type": ["ActionTrigger"],
    "detail": {
      "action": ["print", "email", "fax"]
    }
  })
}

# EventBridge Targets
resource "aws_cloudwatch_event_target" "print_target" {
  rule      = aws_cloudwatch_event_rule.trigger_rule.name
  arn       = aws_lambda_function.print_lambda.arn
  input     = jsonencode({ action = "print" })
}

resource "aws_cloudwatch_event_target" "email_target" {
  rule = aws_cloudwatch_event_rule.trigger_rule.name
  arn  = aws_lambda_function.email_lambda.arn
  input = jsonencode({ action = "email" })
}

resource "aws_cloudwatch_event_target" "fax_target" {
  rule = aws_cloudwatch_event_rule.trigger_rule.name
  arn  = aws_lambda_function.fax_lambda.arn
  input = jsonencode({ action = "fax" })
}



# #EventBridge to invoke your Lambda functions
# resource "aws_lambda_permission" "allow_eventbridge_print" {
#   statement_id  = "AllowExecutionFromEventBridgePrint"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.print_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.trigger_rule.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_email" {
#   statement_id  = "AllowExecutionFromEventBridgeEmail"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.email_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.trigger_rule.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_fax" {
#   statement_id  = "AllowExecutionFromEventBridgeFax"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.fax_lambda.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.trigger_rule.arn
# }


# API Gateway
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "LambdaAPI"
  description = "API Gateway for triggering Lambda functions"
}

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "trigger"
}

resource "aws_api_gateway_method" "lambda_post" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.lambda_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.request_handler.invoke_arn
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "lambda_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "prod"

  depends_on = [aws_api_gateway_integration.lambda_integration]
}
