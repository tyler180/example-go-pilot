data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

locals {
  name      = "example-go-pilot"
  repo_root = abspath("${path.module}/..")

  source_files = setunion(
    fileset(local.repo_root, "**/*.go"),
    fileset(local.repo_root, "go.mod"),
    fileset(local.repo_root, "go.sum"),
    fileset(local.repo_root, "Dockerfile"),
    fileset(local.repo_root, ".dockerignore")
  )

  source_hash = sha256(join("", [
    for file in sort(tolist(local.source_files)) :
    "${file}:${filesha256("${local.repo_root}/${file}")}"
  ]))
}

module "go_test_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.8.0"

  function_name             = local.name
  description               = "go test"
  create_package            = false
  role_name                 = "example-go-pilot-lambda"
  role_permissions_boundary = "arn:aws:iam::138013422358:policy/example-go-pilot-lambda-boundary"

  image_uri    = module.go_test_build.image_uri
  package_type = "Image"

  timeout     = 30
  memory_size = 128

  # allowed_triggers = {
  #   MFLSync = {
  #     principal  = "events.amazonaws.com"
  #     source_arn = aws_cloudwatch_event_rule.mfl_sync.arn
  #     # source_arn = "arn:aws:events:us-west-2:${data.aws_caller_identity.current.account_id}:rule/${local.name}-mfl-sync"
  #   }
  #   AllowExecutionFromHTTPAPI = {
  #     principal  = "apigateway.amazonaws.com"
  #     source_arn = "${data.aws_apigatewayv2_api.backend.execution_arn}/*/*"
  #   }
  # }

  attach_cloudwatch_logs_policy = true

  tags = data.context_tags.backend.tags
}

module "go_test_build" {
  source  = "terraform-aws-modules/lambda/aws//modules/docker-build"
  version = "8.8.0"

  create_ecr_repo = true
  ecr_repo        = local.name
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 5 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 5
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })

  use_image_tag = false # If false, sha of the image will be used
  # use_image_tag = true
  # image_tag     = "1.0"

  source_path      = local.repo_root
  docker_file_path = "${local.repo_root}/Dockerfile"
  platform         = "linux/amd64"
  scan_on_push     = true

  triggers = {
    dir_sha = local.source_hash
  }
}
